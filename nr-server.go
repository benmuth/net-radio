package main

import (
	"fmt"
	"net/http"
	"os"
)

const (
	stationFile = "station.txt"
	// htmlFile    = "index.html"
	htmlFile = "/home/pidio/index.html"
	port     = 80
)

var html []byte

func init() {
	var err error
	html, err = os.ReadFile(htmlFile)
	if err != nil {
		panic(err)
	}
}

func main() {
	http.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		w.Write(html)
	})

	http.HandleFunc("GET /get_station", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)
		station, err := os.ReadFile(stationFile)
		if err != nil {
			panic(err)
		}
		w.Write([]byte(station))
	})

	http.HandleFunc("POST /submit", func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()

		if err != nil {
			http.Error(w, "Error parsing form", http.StatusBadRequest)
			return
		}

		station := r.Form.Get("station")
		err = os.WriteFile(stationFile, []byte(station), 0644)
		if err != nil {
			fmt.Printf("Error writing to station file: %v\n", err)
		}

		w.Header().Set("Location", "/")
		w.WriteHeader(http.StatusSeeOther)
	})

	fmt.Printf("Server running on port %d\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		panic(err)
	}
}
