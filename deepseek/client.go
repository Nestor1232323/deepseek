package deepseek

import (
    "bufio"
    "bytes"
    "context"
    "encoding/base64"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "strings"
    "time"
)

type Client struct {
    config        *Config
    httpClient    *http.Client
    wasmSolver    *WASMSolver
    chatSessionId string
    parentMessageId *int64
}

func NewClient(config *Config) *Client {
    if config.Timeout == 0 {
        config.Timeout = 30 * time.Second
    }
    if config.BaseURL == "" {
        config.BaseURL = "https://chat.deepseek.com"
    }
    if config.WASMPath == "" {
        config.WASMPath = "pow.wasm"
    }

    return &Client{
        config: config,
        httpClient: &http.Client{
            Timeout: config.Timeout,
        },
    }
}

func (c *Client) Init(ctx context.Context) error {
    solver, err := NewWASMSolver(c.config.WASMPath)
    if err != nil {
        return fmt.Errorf("failed to create wasm solver: %w", err)
    }
    
    if err := solver.Init(ctx); err != nil {
        return fmt.Errorf("failed to init wasm: %w", err)
    }
    
    c.wasmSolver = solver
    return nil
}

func (c *Client) Close(ctx context.Context) error {
    if c.wasmSolver != nil {
        return c.wasmSolver.Close(ctx)
    }
    return nil
}

func (c *Client) getHeaders() http.Header {
    headers := http.Header{}
    headers.Set("accept", "*/*")
    headers.Set("content-type", "application/json")
    headers.Set("authorization", c.config.AuthorizationToken)
    headers.Set("cookie", "ds_session_id="+c.config.DsSessionID)
    headers.Set("user-agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36")
    return headers
}

func (c *Client) GetChallenge(ctx context.Context, targetPath string) (map[string]interface{}, error) {
    url := c.config.BaseURL + "/api/v0/chat/create_pow_challenge"
    
    body := map[string]string{"target_path": targetPath}
    jsonBody, err := json.Marshal(body)
    if err != nil {
        return nil, err
    }

    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
    if err != nil {
        return nil, err
    }
    
    req.Header = c.getHeaders()

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("status: %d", resp.StatusCode)
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    if code, ok := result["code"].(float64); ok && code == 0 {
        if data, ok := result["data"].(map[string]interface{}); ok {
            if bizData, ok := data["biz_data"].(map[string]interface{}); ok {
                if challenge, ok := bizData["challenge"].(map[string]interface{}); ok {
                    return challenge, nil
                }
            }
        }
    }
    
    return nil, fmt.Errorf("challenge not found")
}
func (c *Client) DeleteChat(ctx context.Context, chatSessionId string) error {
    url := c.config.BaseURL + "/api/v0/chat_session/delete"
    
    jsonBody := []byte(`{"chat_session_id":"` + chatSessionId + `"}`)
    
    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
    if err != nil {
        return fmt.Errorf("create request: %w", err)
    }
    
    req.Header.Set("accept", "*/*")
    req.Header.Set("content-type", "application/json")
    req.Header.Set("authorization", c.config.AuthorizationToken)
    req.Header.Set("cookie", "ds_session_id="+c.config.DsSessionID)
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("http: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != 200 {
        body, _ := io.ReadAll(resp.Body)
        return fmt.Errorf("status %d: %s", resp.StatusCode, string(body))
    }
    
    return nil
}
func (c *Client) SolvePow(ctx context.Context, challengeData map[string]interface{}) (int, string, error) {
    if c.wasmSolver == nil {
        return 0, "", fmt.Errorf("wasm not initialized")
    }

    challenge := &Challenge{
        Challenge:  challengeData["challenge"].(string),
        Salt:       challengeData["salt"].(string),
        Difficulty: challengeData["difficulty"].(float64),
        TargetPath: challengeData["target_path"].(string),
        Signature:  challengeData["signature"].(string),
        ExpireAt:   int64(challengeData["expire_at"].(float64)),
    }

    answer, err := c.wasmSolver.Solve(ctx, challenge)
    if err != nil {
        return 0, "", err
    }

    powResponseObj := map[string]interface{}{
        "algorithm":   "DeepSeekHashV1",
        "challenge":   challenge.Challenge,
        "salt":        challenge.Salt,
        "answer":      answer,
        "signature":   challenge.Signature,
        "target_path": challenge.TargetPath,
    }

    jsonData, err := json.Marshal(powResponseObj)
    if err != nil {
        return 0, "", err
    }

    return answer, base64.StdEncoding.EncodeToString(jsonData), nil
}

func (c *Client) CreateSession(ctx context.Context) (string, error) {
    url := c.config.BaseURL + "/api/v0/chat_session/create"
    
    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader([]byte("{}")))
    if err != nil {
        return "", err
    }
    
    req.Header = c.getHeaders()

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return "", fmt.Errorf("status: %d", resp.StatusCode)
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return "", err
    }

    if data, ok := result["data"].(map[string]interface{}); ok {
        if bizData, ok := data["biz_data"].(map[string]interface{}); ok {
            if id, ok := bizData["id"].(string); ok {
                c.chatSessionId = id
                return id, nil
            }
        }
    }
    
    return "", fmt.Errorf("session id not found")
}

func (c *Client) GetChats(ctx context.Context) (map[string]interface{}, error) {
    url := c.config.BaseURL + "/api/v0/chat_session/fetch_page?lte_cursor.pinned=false"
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    req.Header = c.getHeaders()

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("status: %d", resp.StatusCode)
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    if data, ok := result["data"].(map[string]interface{}); ok {
        if bizData, ok := data["biz_data"].(map[string]interface{}); ok {
            return bizData, nil
        }
    }
    
    return nil, fmt.Errorf("biz_data not found")
}

func (c *Client) GetChatHistory(ctx context.Context, chatSessionId string) (map[string]interface{}, error) {
    url := c.config.BaseURL + "/api/v0/chat/history_messages?chat_session_id=" + chatSessionId
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    headers := c.getHeaders()
    headers.Set("x-client-bundle-id", "com.deepseek.chat")
    headers.Set("x-client-locale", "ru")
    headers.Set("x-client-platform", "web")
    headers.Set("x-client-timezone-offset", "10800")
    headers.Set("x-client-version", "2.2.0")
    headers.Set("referer", fmt.Sprintf("https://chat.deepseek.com/a/chat/s/%s", chatSessionId))
    
    req.Header = headers

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("status: %d", resp.StatusCode)
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    if data, ok := result["data"].(map[string]interface{}); ok {
        if bizData, ok := data["biz_data"].(map[string]interface{}); ok {
            messages, _ := bizData["chat_messages"].([]interface{})
            return map[string]interface{}{
                "items": messages,
                "total": len(messages),
            }, nil
        }
    }
    
    return map[string]interface{}{
        "items": []interface{}{},
        "total": 0,
    }, nil
}

func (c *Client) GetCurrentUser(ctx context.Context) (map[string]interface{}, error) {
    url := c.config.BaseURL + "/api/v0/users/current"
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    req.Header = c.getHeaders()

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("status: %d", resp.StatusCode)
    }

    var result map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }

    return result, nil
}

func (c *Client) SendMessage(ctx context.Context, message string, thinkingEnabled bool, searchEnabled bool, modelType string, chatId string) (map[string]interface{}, error) {
    if chatId != "" {
        c.chatSessionId = chatId
    } else if c.chatSessionId == "" {
        newId, err := c.CreateSession(ctx)
        if err != nil {
            return map[string]interface{}{
                "ok": false,
                "content": "Can't create session",
            }, nil
        }
        c.chatSessionId = newId
    }

    challengeData, err := c.GetChallenge(ctx, "/api/v0/chat/completion")
    if err != nil {
        return map[string]interface{}{
            "ok": false,
            "content": "Can't get challenge",
        }, nil
    }

    _, powResponse, err := c.SolvePow(ctx, challengeData)
    if err != nil {
        return map[string]interface{}{
            "ok": false,
            "content": "Can't solve PoW: " + err.Error(),
        }, nil
    }

    url := c.config.BaseURL + "/api/v0/chat/completion"
    
    headers := c.getHeaders()
    headers.Set("x-ds-pow-response", powResponse)
    headers.Set("accept", "text/event-stream")
    headers.Set("x-client-bundle-id", "com.deepseek.chat")
    headers.Set("x-client-locale", "ru")
    headers.Set("x-client-platform", "web")
    headers.Set("x-client-timezone-offset", "10800")
    headers.Set("x-client-version", "2.2.0")
    headers.Set("referer", fmt.Sprintf("https://chat.deepseek.com/a/chat/s/%s", c.chatSessionId))

    modelTypeVal := "default"
    if modelType != "" {
        modelTypeVal = modelType
    }
    
    data := map[string]interface{}{
        "chat_session_id":   c.chatSessionId,
        "parent_message_id": nil,
        "model_type":        modelTypeVal,
        "prompt":            message,
        "ref_file_ids":      []string{},
        "thinking_enabled":  thinkingEnabled,
        "search_enabled":    searchEnabled,
        "action":            nil,
        "preempt":           false,
    }

    jsonBody, err := json.Marshal(data)
    if err != nil {
        return nil, err
    }

    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
    if err != nil {
        return nil, err
    }
    req.Header = headers

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        body, _ := io.ReadAll(resp.Body)
        return map[string]interface{}{
            "ok": false,
            "content": string(body),
        }, nil
    }
	fullResponse := ""
	var title *string
	var messageId *int64
	var waitingForTitle bool

	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024)

	for scanner.Scan() {
		line := scanner.Text()

		if strings.HasPrefix(line, "event: title") {
			waitingForTitle = true
			continue
		}

		if waitingForTitle && strings.HasPrefix(line, "data: ") {
			dataStr := strings.TrimPrefix(line, "data: ")
			var event map[string]interface{}
			if err := json.Unmarshal([]byte(dataStr), &event); err == nil {
				if content, ok := event["content"].(string); ok {
					title = &content
				}
			}
			waitingForTitle = false
			continue
		}

		if strings.HasPrefix(line, "data: ") {
            dataStr := strings.TrimPrefix(line, "data: ")
            
            var event map[string]interface{}
            if err := json.Unmarshal([]byte(dataStr), &event); err != nil {
                continue
            }

            if v, ok := event["v"].(map[string]interface{}); ok {
                if response, ok := v["response"].(map[string]interface{}); ok {
                    if msgId, ok := response["message_id"].(float64); ok {
                        id := int64(msgId)
                        messageId = &id
                    }

                    if fragments, ok := response["fragments"].([]interface{}); ok {
                        for _, frag := range fragments {
                            if f, ok := frag.(map[string]interface{}); ok {
                                if fType, ok := f["type"].(string); ok && fType == "RESPONSE" {
                                    if content, ok := f["content"].(string); ok {
                                        fullResponse += content
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if p, ok := event["p"].(string); ok && strings.HasSuffix(p, "/content") {
                if o, ok := event["o"].(string); ok && o == "APPEND" {
                    if v, ok := event["v"].(string); ok {
                        fullResponse += v
                    }
                }
            }

            if _, ok := event["p"]; !ok {
                if v, ok := event["v"].(string); ok && v != "" && !strings.Contains(v, "FINISHED") {
                    fullResponse += v
                }
            }

            if event["title"] != nil {
                if titleMap, ok := event["title"].(map[string]interface{}); ok {
                    if content, ok := titleMap["content"].(string); ok {
                        title = &content
                    }
                }
            }
        }
    }

    if strings.HasSuffix(fullResponse, "FINISHED") {
        fullResponse = fullResponse[:len(fullResponse)-8]
    }

    result := map[string]interface{}{
        "ok": true,
        "content": fullResponse,
        "chatId": c.chatSessionId,
        "title": "",
    }

    if title != nil {
        result["title"] = *title
    }

    if messageId != nil {
        result["messageId"] = *messageId
        result["parentMessageId"] = *messageId
    }

    return result, nil
}

func (c *Client) ContinueChat(ctx context.Context, chatId string, parentMessageId int64, message string, thinkingEnabled bool, searchEnabled bool) (map[string]interface{}, error) {
    if chatId == "" {
        return map[string]interface{}{
            "ok": false,
            "content": "chatId required",
        }, nil
    }

    if parentMessageId <= 0 {
        return map[string]interface{}{
            "ok": false,
            "content": "parentMessageId must be > 0",
        }, nil
    }

    c.chatSessionId = chatId
    c.parentMessageId = &parentMessageId

    challengeData, err := c.GetChallenge(ctx, "/api/v0/chat/completion")
    if err != nil {
        return map[string]interface{}{
            "ok": false,
            "content": "Can't get challenge",
        }, nil
    }

    _, powResponse, err := c.SolvePow(ctx, challengeData)
    if err != nil {
        return map[string]interface{}{
            "ok": false,
            "content": "Can't solve PoW: " + err.Error(),
        }, nil
    }

    url := c.config.BaseURL + "/api/v0/chat/completion"
    
    headers := c.getHeaders()
    headers.Set("x-ds-pow-response", powResponse)
    headers.Set("accept", "text/event-stream")
    headers.Set("x-client-bundle-id", "com.deepseek.chat")
    headers.Set("x-client-locale", "ru")
    headers.Set("x-client-platform", "web")
    headers.Set("x-client-timezone-offset", "10800")
    headers.Set("x-client-version", "2.2.0")
    headers.Set("referer", fmt.Sprintf("https://chat.deepseek.com/a/chat/s/%s", c.chatSessionId))

    data := map[string]interface{}{
        "chat_session_id":   c.chatSessionId,
        "parent_message_id": c.parentMessageId,
        "model_type":        nil,
        "prompt":            message,
        "ref_file_ids":      []string{},
        "thinking_enabled":  thinkingEnabled,
        "search_enabled":    searchEnabled,
        "action":            nil,
        "preempt":           false,
    }

    jsonBody, err := json.Marshal(data)
    if err != nil {
        return nil, err
    }

    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
    if err != nil {
        return nil, err
    }
    req.Header = headers

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        body, _ := io.ReadAll(resp.Body)
        return map[string]interface{}{
            "ok": false,
            "content": string(body),
        }, nil
    }

    fullResponse := ""
    var title *string
    var messageId *int64
    var parentId *int64

    scanner := bufio.NewScanner(resp.Body)
    scanner.Buffer(make([]byte, 1024*1024), 1024*1024)

    for scanner.Scan() {
        line := scanner.Text()

        if strings.HasPrefix(line, "data: ") {
            dataStr := strings.TrimPrefix(line, "data: ")
            
            var event map[string]interface{}
            if err := json.Unmarshal([]byte(dataStr), &event); err != nil {
                continue
            }

            if v, ok := event["v"].(map[string]interface{}); ok {
                if response, ok := v["response"].(map[string]interface{}); ok {
                    if msgId, ok := response["message_id"].(float64); ok {
                        id := int64(msgId)
                        messageId = &id
                    }
                    
                    if pId, ok := response["parent_id"].(float64); ok {
                        id := int64(pId)
                        parentId = &id
                    }

                    if fragments, ok := response["fragments"].([]interface{}); ok {
                        for _, frag := range fragments {
                            if f, ok := frag.(map[string]interface{}); ok {
                                if fType, ok := f["type"].(string); ok && fType == "RESPONSE" {
                                    if content, ok := f["content"].(string); ok {
                                        fullResponse += content
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if p, ok := event["p"].(string); ok && strings.HasSuffix(p, "/content") {
                if o, ok := event["o"].(string); ok && o == "APPEND" {
                    if v, ok := event["v"].(string); ok {
                        fullResponse += v
                    }
                }
            }

            if _, ok := event["p"]; !ok {
                if v, ok := event["v"].(string); ok && v != "" && !strings.Contains(v, "FINISHED") {
                    fullResponse += v
                }
            }

            if event["title"] != nil {
                if titleMap, ok := event["title"].(map[string]interface{}); ok {
                    if content, ok := titleMap["content"].(string); ok {
                        title = &content
                    }
                }
            }
        }
    }

    if strings.HasSuffix(fullResponse, "FINISHED") {
        fullResponse = fullResponse[:len(fullResponse)-8]
    }

    if messageId != nil {
        c.parentMessageId = messageId
    }

    result := map[string]interface{}{
        "ok": true,
        "content": fullResponse,
        "chatId": c.chatSessionId,
        "title": "",
    }

    if title != nil {
        result["title"] = *title
    }

    if messageId != nil {
        result["messageId"] = *messageId
        result["parentMessageId"] = *messageId
    }

    if parentId != nil {
        result["parentId"] = *parentId
    }

    return result, nil
}
func min(a, b int) int {
    if a < b {
        return a
    }
    return b
}