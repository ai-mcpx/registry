#!/bin/bash

set -e

echo "Testing optional authorization for MCP server publishing..."
echo "=================================================="

# Configuration
HOST="${HOST:-http://localhost:8080}"
VERBOSE="${VERBOSE:-false}"

# Note: This script expects MongoDB to be running
# To start MongoDB: docker run -d --name mcpx-mongodb -p 27017:27017 mongo:latest
# To start MCP Registry: MCP_REGISTRY_DATABASE_TYPE=mongodb ./registry

# Test payload without GitHub namespace (should succeed without auth)
PAYLOAD_NO_GITHUB='{
  "name": "test-server-optional-auth-'$(date +%s)'",
  "description": "A test server without GitHub namespace",
  "repository": {
    "url": "https://github.com/example/test-server",
    "source": "github",
    "id": "example/test-server"
  },
  "version_detail": {
    "version": "1.0.'$(date +%s)'"
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
    "version": "1.0.'$(date +%s)'"
  }
}'

echo "Registry URL: $HOST"
echo

# Check if the API is running
echo "Checking if the MCP Registry API is running..."
health_check=$(curl -s -o /dev/null -w "%{http_code}" "$HOST/v0/health" 2>/dev/null || echo "000")
if [[ "$health_check" != "200" ]]; then
  echo "❌ Error: MCP Registry API is not running at $HOST (health check returned $health_check)"
  echo "Please start the server and try again."
  exit 1
else
  echo "✅ MCP Registry API is running at $HOST"
fi
echo

# Test 1: Publish without GitHub namespace and without authorization (should succeed)
echo "Test 1: Publishing without GitHub namespace and without authorization..."
echo "Expected: SUCCESS (201 Created)"
echo
if [[ "$VERBOSE" == "true" ]]; then
  echo "Payload: $PAYLOAD_NO_GITHUB"
  echo
fi

echo "Sending request..."
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$HOST/v0/publish" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD_NO_GITHUB")

# Extract HTTP status code
http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo "Response Status: $http_status"
echo "Response Body: $response_body"

if [[ "$http_status" == "201" ]]; then
  echo "✅ Test 1 PASSED: Successfully published without authorization"
else
  echo "❌ Test 1 FAILED: Expected 201, got $http_status"
fi
echo

# Test 2: Publish with GitHub namespace and without authorization (should fail)
echo "Test 2: Publishing with GitHub namespace and without authorization..."
echo "Expected: FAILURE (401 Unauthorized)"
echo
if [[ "$VERBOSE" == "true" ]]; then
  echo "Payload: $PAYLOAD_GITHUB"
  echo
fi

echo "Sending request..."
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$HOST/v0/publish" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD_GITHUB")

# Extract HTTP status code
http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo "Response Status: $http_status"
echo "Response Body: $response_body"

if [[ "$http_status" == "401" ]]; then
  echo "✅ Test 2 PASSED: Correctly rejected GitHub namespace without authorization"
else
  echo "❌ Test 2 FAILED: Expected 401, got $http_status"
fi
echo

# Test 3: Check if the server appears in the list
echo "Test 3: Checking if published server appears in server list..."
echo "Fetching server list..."

list_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$HOST/v0/servers")
list_http_status=$(echo "$list_response" | grep "HTTP_STATUS:" | cut -d: -f2)
list_response_body=$(echo "$list_response" | sed '/HTTP_STATUS:/d')

echo "List Response Status: $list_http_status"

if [[ "$list_http_status" == "200" ]]; then
  echo "✅ Successfully fetched server list"

  # Check if our test server is in the list
  if echo "$list_response_body" | grep -q "test-server-optional-auth"; then
    echo "✅ Test 3 PASSED: Published server found in server list"
  else
    echo "❌ Test 3 FAILED: Published server not found in server list"
    echo "Response body:"
    echo "$list_response_body" | jq . 2>/dev/null || echo "$list_response_body"
  fi
else
  echo "❌ Test 3 FAILED: Could not fetch server list (status: $list_http_status)"
  echo "Response: $list_response_body"
fi

echo
echo "=================================================="
echo "Tests completed!"
