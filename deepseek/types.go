package deepseek

import "time"


type Config struct {
    DsSessionID       string
    AuthorizationToken string
    BaseURL           string
    WASMPath          string
    Timeout           time.Duration
}


type Challenge struct {
    Challenge  string  `json:"challenge"`
    Salt       string  `json:"salt"`
    Difficulty float64 `json:"difficulty"`
    TargetPath string  `json:"target_path"`
    Signature  string  `json:"signature"`
    ExpireAt   int64   `json:"expire_at"`
}


type PowResponse struct {
    Algorithm  string `json:"algorithm"`
    Challenge  string `json:"challenge"`
    Salt       string `json:"salt"`
    Answer     int    `json:"answer"`
    Signature  string `json:"signature"`
    TargetPath string `json:"target_path"`
}


type ChatRequest struct {
    ChatSessionID   string   `json:"chat_session_id"`
    ParentMessageID *int64   `json:"parent_message_id"`
    ModelType       *string  `json:"model_type"`
    Prompt          string   `json:"prompt"`
    RefFileIDs      []string `json:"ref_file_ids"`
    ThinkingEnabled bool     `json:"thinking_enabled"`
    SearchEnabled   bool     `json:"search_enabled"`
    Action          *string  `json:"action"`
    Preempt         bool     `json:"preempt"`
}


type StreamResponse struct {
    Content         string
    MessageID       int64
    ParentMessageID int64
    Role            string
    Title           string
    Done            bool
    Error           error
}


type APIResponse struct {
    Code int         `json:"code"`
    Data *APIResponseData `json:"data,omitempty"`
    Msg  string      `json:"msg,omitempty"`
}


type APIResponseData struct {
    BizData interface{} `json:"biz_data"`
}