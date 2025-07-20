#!/bin/bash

echo "Testing optional authorization for MCP server publishing..."

# Test payload without GitHub namespace (should succeed without auth)
PAYLOAD_NO_GITHUB='{
  "name": "test-server",
  "description": "A test server without GitHub namespace",
  "repository": {
    "url": "https://github.com/example/test-server",
    "source": "github",
    "id": "example/test-server"
  },
  "version_detail": {
    "version": "1.0.0"
  }
}'

# Test payload with GitHub namespace (should require auth)
PAYLOAD_GITHUB='{
  "name": "io.github.user/test-server",
  "description": "A test server with GitHub namespace",
  "repository": {
    "url": "https://github.com/user/test-server",
    "source": "github",
    "id": "user/test-server"
  },
  "version_detail": {
    "version": "1.0.0"
  }
}'

echo "1. Testing publish without GitHub namespace and without authorization (should succeed)..."
echo "Payload: $PAYLOAD_NO_GITHUB"
echo

echo "2. Testing publish with GitHub namespace and without authorization (should fail)..."
echo "Payload: $PAYLOAD_GITHUB"
echo

echo "Note: Run this script against a running MCP registry instance to test the actual behavior."
echo "Example usage:"
echo "  curl -X POST http://localhost:8080/v0/publish -H 'Content-Type: application/json' -d '$PAYLOAD_NO_GITHUB'"
echo "  curl -X POST http://localhost:8080/v0/publish -H 'Content-Type: application/json' -d '$PAYLOAD_GITHUB'"
