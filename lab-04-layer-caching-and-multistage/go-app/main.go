package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Multi-Stage Build Basariyla Calisiyor! (Imaj Boyutu: ~12MB)\n")
	})
	fmt.Println("Sunucu 8080 portunda calisiyor...")
	http.ListenAndServe(":8080", nil)
}
