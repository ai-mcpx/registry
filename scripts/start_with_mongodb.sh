#!/bin/bash

set -e

echo "🚀 Starting MCP Registry with MongoDB..."
echo "=================================================="

# Function to check if MongoDB container is running
check_mongodb() {
    if docker ps --filter "name=mcpx-mongodb" --filter "status=running" --quiet | grep -q .; then
        return 0
    else
        return 1
    fi
}

# Function to check if MongoDB is ready to accept connections
wait_for_mongodb() {
    echo "⏳ Waiting for MongoDB to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec mcpx-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            echo "✅ MongoDB is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts: MongoDB not ready yet..."
        sleep 2
        ((attempt++))
    done

    echo "❌ MongoDB failed to start after $max_attempts attempts"
    return 1
}

# Check if MongoDB container exists and is running
if check_mongodb; then
    echo "✅ MongoDB container is already running"
else
    echo "📦 Starting MongoDB container..."

    # Remove existing container if it exists (but not running)
    if docker ps -a --filter "name=mcpx-mongodb" --quiet | grep -q .; then
        echo "🗑️  Removing existing MongoDB container..."
        docker rm -f mcpx-mongodb
    fi

    # Start new MongoDB container
    docker run -d --name mcpx-mongodb -p 27017:27017 mongo:latest

    # Wait for MongoDB to be ready
    if ! wait_for_mongodb; then
        echo "❌ Failed to start MongoDB"
        exit 1
    fi
fi

echo
echo "🔧 Building MCP Registry..."
cd /workspaces/mcpx
if [ ! -f "./registry" ]; then
    go build -o registry cmd/registry/*.go
    echo "✅ Registry built successfully"
else
    echo "✅ Registry binary already exists"
fi

echo
echo "🏁 Starting MCP Registry with MongoDB..."
echo "   Database Type: MongoDB"
echo "   MongoDB URL: mongodb://localhost:27017"
echo "   Registry URL: http://localhost:8080"
echo

# Kill any existing registry process
pkill -f "./registry" 2>/dev/null || true

# Start the registry with MongoDB
export MCP_REGISTRY_DATABASE_TYPE=mongodb
export MCP_REGISTRY_DATABASE_URL=mongodb://localhost:27017
export MCP_REGISTRY_DATABASE_NAME=mcp-registry
export MCP_REGISTRY_COLLECTION_NAME=servers_v2
export MCP_REGISTRY_SEED_IMPORT=false  # Disable seed file import

./registry &
REGISTRY_PID=$!

echo "🔍 Waiting for Registry to start..."
sleep 5

# Check if registry is running
if curl -s http://localhost:8080/v0/health >/dev/null; then
    echo "✅ MCP Registry is running successfully!"
    echo
    echo "=================================================="
    echo "🎉 Setup Complete!"
    echo "=================================================="
    echo "MongoDB URL: mongodb://localhost:27017"
    echo "Registry URL: http://localhost:8080"
    echo "Health Check: http://localhost:8080/v0/health"
    echo "Servers API: http://localhost:8080/v0/servers"
    echo "Registry PID: $REGISTRY_PID"
    echo
    echo "💡 To test optional auth:"
    echo "   ./scripts/test_optional_auth.sh"
    echo
    echo "🛑 To stop everything:"
    echo "   kill $REGISTRY_PID"
    echo "   docker stop mcpx-mongodb"
    echo "=================================================="
else
    echo "❌ Failed to start MCP Registry"
    kill $REGISTRY_PID 2>/dev/null || true
    exit 1
fi
