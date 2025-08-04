// Package v0 contains API handlers for version 0 of the API
package v0

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"

	_ "github.com/swaggo/files" // Swagger files needed for embedding
	httpSwagger "github.com/swaggo/http-swagger"
	"gopkg.in/yaml.v3"
)

// SwaggerHandler returns a handler that serves the Swagger UI
func SwaggerHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// When accessed directly, redirect to the UI path
		if r.URL.Path == "/v0/swagger" {
			http.Redirect(w, r, "/v0/swagger/", http.StatusFound)
			return
		}

		// Determine the JSON URL based on how we're being accessed
		var jsonURL string
		if r.Header.Get("X-Forwarded-Proto") != "" || r.Header.Get("X-Real-IP") != "" {
			// Being accessed through a proxy (nginx), use external URL
			jsonURL = "/api/swagger/doc.json"
		} else {
			// Direct access, use internal URL
			jsonURL = "/v0/swagger/doc.json"
		}

		// Serve the Swagger UI
		handler := httpSwagger.Handler(
			httpSwagger.URL(jsonURL), // Use the appropriate URL for the JSON
			httpSwagger.DeepLinking(true),
		)

		// Handle other Swagger UI paths
		handler.ServeHTTP(w, r)
	}
}

// SwaggerJSONHandler serves the Swagger specification as JSON
func SwaggerJSONHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Find the project root directory
		workDir, err := os.Getwd()
		if err != nil {
			http.Error(w, "Unable to determine working directory", http.StatusInternalServerError)
			return
		}

		// Path to the swagger YAML file
		swaggerFilePath := filepath.Join(workDir, "internal", "docs", "swagger.yaml")

		// Read the YAML file
		file, err := os.Open(swaggerFilePath)
		if err != nil {
			http.Error(w, "Unable to open swagger file", http.StatusInternalServerError)
			return
		}
		defer file.Close()

		// Read the YAML content
		yamlData, err := io.ReadAll(file)
		if err != nil {
			http.Error(w, "Unable to read swagger file", http.StatusInternalServerError)
			return
		}

		// Parse YAML
		var swaggerSpec interface{}
		err = yaml.Unmarshal(yamlData, &swaggerSpec)
		if err != nil {
			http.Error(w, "Unable to parse swagger YAML", http.StatusInternalServerError)
			return
		}

		// Convert to JSON
		jsonData, err := json.Marshal(swaggerSpec)
		if err != nil {
			http.Error(w, "Unable to convert swagger to JSON", http.StatusInternalServerError)
			return
		}

		// Set content type and serve JSON
		w.Header().Set("Content-Type", "application/json")
		w.Write(jsonData)
	}
}
