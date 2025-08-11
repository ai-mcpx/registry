// Package v0 contains API handlers for version 0 of the API
package v0

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/modelcontextprotocol/registry/internal/model"
	"github.com/modelcontextprotocol/registry/internal/service"
)

// Response is a paginated API response
type PaginatedResponse struct {
	Data     []model.Server `json:"servers"`
	Metadata Metadata       `json:"metadata,omitempty"`
}

// Metadata contains pagination metadata
type Metadata struct {
	NextCursor string `json:"next_cursor,omitempty"`
	Count      int    `json:"count,omitempty"`
	Total      int    `json:"total,omitempty"`
}

// ServersHandler returns a handler for listing registry items
func ServersHandler(registry service.RegistryService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Parse cursor and limit from query parameters
		cursor := r.URL.Query().Get("cursor")
		if cursor != "" {
			_, err := uuid.Parse(cursor)
			if err != nil {
				http.Error(w, "Invalid cursor parameter", http.StatusBadRequest)
				return
			}
		}
		limitStr := r.URL.Query().Get("limit")

		// Default limit if not specified
		limit := 30

		// Try to parse limit from query param
		if limitStr != "" {
			parsedLimit, err := strconv.Atoi(limitStr)
			if err != nil {
				http.Error(w, "Invalid limit parameter", http.StatusBadRequest)
				return
			}

			// Check if limit is within reasonable bounds
			if parsedLimit <= 0 {
				http.Error(w, "Limit must be greater than 0", http.StatusBadRequest)
				return
			}

			// Cap maximum limit to prevent excessive queries
			limit = min(parsedLimit, 100)
		}

		// Use the GetAll method to get paginated results
		registries, nextCursor, err := registry.List(cursor, limit)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Create paginated response
		response := PaginatedResponse{
			Data: registries,
		}

		// Add metadata if there's a next cursor
		if nextCursor != "" {
			response.Metadata = Metadata{
				NextCursor: nextCursor,
				Count:      len(registries),
			}
		}

		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(response); err != nil {
			http.Error(w, "Failed to encode response", http.StatusInternalServerError)
			return
		}
	}
}

// ServersDetailHandler returns a handler for getting details of a specific server by ID
func ServersDetailHandler(registry service.RegistryService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Extract the server ID from the URL path
		id := r.PathValue("id")

		// Validate that the ID is a valid UUID
		_, err := uuid.Parse(id)
		if err != nil {
			http.Error(w, "Invalid server ID format", http.StatusBadRequest)
			return
		}

		switch r.Method {
		case http.MethodGet:
			handleGetServer(w, r, registry, id)
		case http.MethodPut:
			handleUpdateServer(w, r, registry, id)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
	}
}

// handleGetServer handles GET requests for server details
func handleGetServer(w http.ResponseWriter, r *http.Request, registry service.RegistryService, id string) {
	// Get the server details from the registry service
	serverDetail, err := registry.GetByID(id)
	if err != nil {
		if err.Error() == "record not found" {
			http.Error(w, "Server not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Error retrieving server details", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(serverDetail); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// handleUpdateServer handles PUT requests for updating server details
func handleUpdateServer(w http.ResponseWriter, r *http.Request, registry service.RegistryService, id string) {
	// Read the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Parse request body into ServerDetail struct
	var serverDetail model.ServerDetail
	err = json.Unmarshal(body, &serverDetail)
	if err != nil {
		http.Error(w, "Invalid request payload: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Validate required fields
	if serverDetail.Name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}

	// Call the update method on the registry service
	err = registry.Update(id, &serverDetail)
	if err != nil {
		// Check for specific error types and return appropriate HTTP status codes
		if err.Error() == "record not found" {
			http.Error(w, "Server not found", http.StatusNotFound)
			return
		}
		if err.Error() == "invalid input" {
			http.Error(w, "Invalid input data", http.StatusBadRequest)
			return
		}
		if err.Error() == "invalid version: cannot publish older version after newer version" {
			http.Error(w, "Invalid version: cannot update to an older version", http.StatusBadRequest)
			return
		}
		if err.Error() == "record already exists" {
			http.Error(w, "A server with this version already exists", http.StatusConflict)
			return
		}
		http.Error(w, "Failed to update server details: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(map[string]string{
		"message": "Server updated successfully",
		"id":      id,
	}); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}
