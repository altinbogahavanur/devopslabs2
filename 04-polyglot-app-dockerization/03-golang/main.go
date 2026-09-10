package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

type Response struct {
	Message   string `json:"message"`
	GoVersion string `json:"go_version"`
	OS        string `json:"os"`
	Arch      string `json:"arch"`
	Timestamp string `json:"timestamp"`
}

type HealthResponse struct {
	Status string `json:"status"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		resp := Response{
			Message:   "Go Microservice Basariyla Calisiyor! (Multi-Stage / Scratch)",
			GoVersion: runtime.Version(),
			OS:        runtime.GOOS,
			Arch:      runtime.GOARCH,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(resp)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(HealthResponse{Status: "healthy"})
	})

	log.Printf("🚀 Go Microservice baslatildi. Dinlenen port: %s\n", port)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil); err != nil {
		log.Fatalf("Sunucu hatasi: %v", err)
	}
}
