package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
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
		stations, err := os.ReadFile(stationFile)
		if err != nil {
			panic(err)
		}

		w.Write([]byte(stations))
	})

	http.HandleFunc("POST /submit", func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()

		if err != nil {
			http.Error(w, "Error parsing form", http.StatusBadRequest)
			return
		}

		station := r.Form.Get("station")
		f, err := os.OpenFile(stationFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		defer func() {
			err := f.Close()
			if err != nil {
				fmt.Printf("failed to close station file: %v\n", err)
			}
		}()
		_, err = fmt.Fprintf(f, "\n%s", station)
		if err != nil {
			fmt.Printf("Error writing to station file: %v\n", err)
		}

		w.Header().Set("Location", "/")
		w.WriteHeader(http.StatusSeeOther)
	})
	http.HandleFunc("POST /next", func(w http.ResponseWriter, r *http.Request) {
		stations, err := os.ReadFile(stationFile)
		if err != nil {
			panic(err)
		}
		lines := strings.Split(strings.Trim(string(stations), "\n"), "\n")
		rotated := append(lines[1:], lines[0])
		err = os.WriteFile(stationFile, []byte(strings.Join(rotated, "\n")), 0644)
		if err != nil {
			panic(err)
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
