#!/bin/bash

echo "🛑 Stopping MCP Registry and MongoDB..."
echo "=================================================="

# Stop MCP Registry
echo "🔴 Stopping MCP Registry..."
if pkill -f "./registry"; then
    echo "✅ MCP Registry stopped"
else
    echo "ℹ️  No MCP Registry process found"
fi

# Stop MongoDB container
echo "🔴 Stopping MongoDB container..."
if docker ps --filter "name=mcpx-mongodb" --filter "status=running" --quiet | grep -q .; then
    docker stop mcpx-mongodb
    echo "✅ MongoDB container stopped"
else
    echo "ℹ️  MongoDB container is not running"
fi

echo
echo "=================================================="
echo "✅ Cleanup Complete!"
echo "=================================================="
echo "💡 To restart everything:"
echo "   ./start_with_mongodb.sh"
echo "=================================================="
