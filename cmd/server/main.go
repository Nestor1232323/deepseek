package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "time"

    "github.com/joho/godotenv"

    "deepseek-go/api"
    "deepseek-go/deepseek"
)

func main() {

    if err := godotenv.Load(); err != nil {
        log.Println("Warning: .env file not found")
    }


    dsSessionID := os.Getenv("DS_SESSION_ID")
    authToken := os.Getenv("AUTHORIZATION_TOKEN")
    port := os.Getenv("PORT")
    host := os.Getenv("HOST")
    wasmPath := os.Getenv("WASM_PATH")

    if dsSessionID == "" || authToken == "" {
        log.Fatal("DS_SESSION_ID and AUTHORIZATION_TOKEN must be set in .env")
    }

    if port == "" {
        port = "45516"
    }
    if host == "" {
        host = "0.0.0.0"
    }
    if wasmPath == "" {
        wasmPath = "pow.wasm"
    }


    config := &deepseek.Config{
        DsSessionID:       dsSessionID,
        AuthorizationToken: authToken,
        BaseURL:           "https://chat.deepseek.com",
        WASMPath:          wasmPath,
        Timeout:           60 * time.Second,
    }

    client := deepseek.NewClient(config)
    

    ctx := context.Background()
    if err := client.Init(ctx); err != nil {
        log.Fatalf("❌ Failed to initialize client: %v", err)
    }
    defer client.Close(ctx)



    server := api.NewServer(client)


    addr := host + ":" + port
    log.Printf("API server running on http://%s", addr)

    if err := http.ListenAndServe(addr, server); err != nil {
        log.Fatalf("Server error: %v", err)
    }
}