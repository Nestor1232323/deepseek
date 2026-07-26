package api

import (
    "context"
    "encoding/json"
    "io"
    "net/http"
    "strings"
	"log"
    "deepseek-go/deepseek"
)

type Server struct {
    client *deepseek.Client
    ctx    context.Context
}

func NewServer(client *deepseek.Client) *Server {
    return &Server{
        client: client,
        ctx:    context.Background(),
    }
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Access-Control-Allow-Origin", "*")
    w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
    w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

    if r.Method == "OPTIONS" {
        w.WriteHeader(200)
        return
    }

    path := r.URL.Path

    switch {
    case r.Method == "GET" && path == "/api/v1/status":
        s.handleStatus(w, r)
    case r.Method == "GET" && path == "/api/v1/me":
        s.handleMe(w, r)
    case r.Method == "GET" && path == "/api/v1/chats":
        s.handleChats(w, r)
    case r.Method == "DELETE" && strings.HasPrefix(path, "/api/v1/chats/"):
        s.handleDeleteChat(w, r)
    case r.Method == "POST" && path == "/api/v1/chats/edit":
        s.handleEdit(w, r)
    case r.Method == "POST" && path == "/api/v1/chats/continue":
        s.handleContinue(w, r)
    case r.Method == "POST" && path == "/api/v1/chats/history":
        s.handleHistory(w, r)
    case r.Method == "POST" && path == "/api/v1/chats/completion":
        s.handleCompletion(w, r)
    default:
        s.sendError(w, "Not found", 404)
    }
}

func (s *Server) handleStatus(w http.ResponseWriter, r *http.Request) {
    s.sendJSON(w, map[string]interface{}{
        "ok":     true,
        "status": "running",
    })
}

func (s *Server) handleMe(w http.ResponseWriter, r *http.Request) {
    user, err := s.client.GetCurrentUser(r.Context())
    if err != nil {
        s.sendError(w, "Failed to get user info", 500)
        return
    }
    s.sendJSON(w, user)
}

func (s *Server) handleChats(w http.ResponseWriter, r *http.Request) {
    chats, err := s.client.GetChats(r.Context())
    if err != nil {
        s.sendError(w, "Failed to get chats", 500)
        return
    }
    s.sendJSON(w, map[string]interface{}{
        "ok":   true,
        "data": chats,
    })
}
func (s *Server) handleDeleteChat(w http.ResponseWriter, r *http.Request) {
    chatId := strings.TrimPrefix(r.URL.Path, "/api/v1/chats/")
    
    if chatId == "" || chatId == r.URL.Path {
        s.sendError(w, "chatId required", 400)
        return
    }
    
    if err := s.client.DeleteChat(r.Context(), chatId); err != nil {
        log.Printf("❌ Delete error: %v", err)
        s.sendError(w, err.Error(), 500)
        return
    }
    
    s.sendJSON(w, map[string]interface{}{"ok": true})
}
func (s *Server) handleEdit(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        s.sendError(w, "Invalid body", 400)
        return
    }
    defer r.Body.Close()

    var req map[string]interface{}
    if err := json.Unmarshal(body, &req); err != nil {
        s.sendError(w, "Invalid JSON", 400)
        return
    }

    chatId, _ := req["chatId"].(string)
    messageId, _ := req["messageId"].(string)
    prompt, _ := req["prompt"].(string)

    if chatId == "" || messageId == "" || prompt == "" {
        s.sendError(w, "chatId, messageId and prompt required", 400)
        return
    }


    s.sendJSON(w, map[string]interface{}{
        "ok":   true,
        "data": "Edit not implemented",
    })
}

func (s *Server) handleContinue(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        s.sendError(w, "Invalid body", 400)
        return
    }
    defer r.Body.Close()

    var req map[string]interface{}
    if err := json.Unmarshal(body, &req); err != nil {
        s.sendError(w, "Invalid JSON", 400)
        return
    }

    chatId, _ := req["chatId"].(string)
    parentMessageId, _ := req["parentMessageId"].(float64)
    message, _ := req["message"].(string)
    thinking, _ := req["thinking"].(bool)
    search, _ := req["search"].(bool)

    if chatId == "" || parentMessageId == 0 || message == "" {
        s.sendError(w, "chatId, parentMessageId and message required", 400)
        return
    }

	result, err := s.client.ContinueChat(
		r.Context(),
		chatId,
		int64(parentMessageId),
		message,
		thinking,
		search,
	)
    if err != nil {
        s.sendError(w, err.Error(), 500)
        return
    }

    s.sendJSON(w, result)
}

func (s *Server) handleHistory(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        s.sendError(w, "Invalid body", 400)
        return
    }
    defer r.Body.Close()

    var req map[string]interface{}
    if err := json.Unmarshal(body, &req); err != nil {
        s.sendError(w, "Invalid JSON", 400)
        return
    }

    chatId, _ := req["chatId"].(string)

    if chatId == "" {
        s.sendError(w, "chatId required", 400)
        return
    }

    history, err := s.client.GetChatHistory(r.Context(), chatId)
    if err != nil {
        s.sendError(w, "Failed to get history", 500)
        return
    }

    s.sendJSON(w, map[string]interface{}{
        "ok": true,
        "data": map[string]interface{}{
            "chat_messages": history["items"],
        },
    })
}

func (s *Server) handleCompletion(w http.ResponseWriter, r *http.Request) {
    body, err := io.ReadAll(r.Body)
    if err != nil {
        s.sendError(w, "Invalid body", 400)
        return
    }
    defer r.Body.Close()

    var req map[string]interface{}
    if err := json.Unmarshal(body, &req); err != nil {
        s.sendError(w, "Invalid JSON", 400)
        return
    }

    message, _ := req["message"].(string)
    thinking, _ := req["thinking"].(bool)
    search, _ := req["search"].(bool)
    model, _ := req["model"].(string)
    chatId, _ := req["chatId"].(string)

    if message == "" {
        s.sendError(w, "message required", 400)
        return
    }

	result, err := s.client.SendMessage(
		r.Context(),
		message,
		thinking,
		search,
		model,  // передаем model
		chatId,
	)

    if err != nil {
        s.sendError(w, err.Error(), 500)
        return
    }

    s.sendJSON(w, result)
}

func (s *Server) sendJSON(w http.ResponseWriter, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(200)
    json.NewEncoder(w).Encode(data)
}

func (s *Server) sendError(w http.ResponseWriter, message string, status int) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "ok":    false,
        "error": message,
    })
}