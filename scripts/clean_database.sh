#!/bin/bash

echo "🗑️  Cleaning MCP Registry Database..."
echo "=================================================="

# Function to check if MongoDB container is running
check_mongodb() {
    if docker ps --filter "name=mcpx-mongodb" --filter "status=running" --quiet | grep -q .; then
        return 0
    else
        return 1
    fi
}

if ! check_mongodb; then
    echo "❌ MongoDB container is not running"
    echo "💡 Start MongoDB first: docker run -d --name mcpx-mongodb -p 27017:27017 mongo:latest"
    exit 1
fi

echo "⚠️  This will delete ALL data in the MCP Registry database!"
echo "Database: mcp-registry"
echo "Collection: servers_v2"
echo
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled"
    exit 0
fi

echo
echo "🗑️  Dropping the servers_v2 collection..."
docker exec mcpx-mongodb mongosh mcp-registry --eval "db.servers_v2.drop()"

echo "✅ Database cleaned successfully!"
echo
echo "📊 Current database status:"
docker exec mcpx-mongodb mongosh mcp-registry --eval "db.stats()"

echo
echo "=================================================="
echo "✅ Cleanup Complete!"
echo "=================================================="
echo "💡 The database is now empty and ready for fresh data."
echo "🔄 You can restart the registry to begin with a clean state."
echo "=================================================="
