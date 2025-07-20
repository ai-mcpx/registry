# MongoDB Setup with Disabled Seed Import

## ✅ What We've Accomplished

1. **Configured MongoDB**: MCP Registry now uses MongoDB for persistent data storage
2. **Disabled Seed Import**: The `data/seed_2025_05_16.json` file is NOT imported into the database
3. **Maintained Optional Auth**: The optional authorization feature continues to work with MongoDB
4. **Created Management Scripts**: Easy-to-use scripts for starting, stopping, and cleaning the database

## 🔧 Configuration

The following environment variables control seed import:

- `MCP_REGISTRY_SEED_IMPORT=false` - Disables seed file import
- `MCP_REGISTRY_SEED_FILE_PATH` - Path to seed file (not used when import is disabled)

## 📁 Available Scripts

### Start Everything with MongoDB (No Seed Import)
```bash
./start_with_mongodb.sh
```
- Starts MongoDB container if not running
- Builds and starts MCP Registry with MongoDB
- **Seed import is DISABLED**

### Test Optional Authorization
```bash
./scripts/test_optional_auth.sh
```
- Tests publishing without authorization (non-GitHub namespace)
- Tests that GitHub namespace still requires authorization
- Verifies data persists in MongoDB

### Clean Database
```bash
./clean_database.sh
```
- Removes ALL data from the MongoDB collection
- Provides confirmation prompt for safety
- Useful for starting fresh

### Stop Everything
```bash
./stop_services.sh
```
- Stops MCP Registry process
- Stops MongoDB container

## 🗃️ Database Status

- **Database**: `mcp-registry`
- **Collection**: `servers_v2`
- **Seed Import**: **DISABLED** ❌
- **Data Source**: Only manually published servers via API

## 🔍 Current Data

You can check what's in the database:

```bash
# Via API
curl -s http://localhost:8080/v0/servers | jq .

# Via MongoDB directly
docker exec mcpx-mongodb mongosh mcp-registry --eval "db.servers_v2.find().pretty()"
```

## 🚀 Testing Results

✅ **Optional Authorization Working**:
- Non-GitHub namespaces: No auth required
- GitHub namespaces (`io.github.*`): Auth required
- Data persists in MongoDB
- No seed data imported

## 💡 Manual Control

If you want to control seed import manually:

```bash
# Disable seed import (current setting)
MCP_REGISTRY_SEED_IMPORT=false ./registry

# Enable seed import (if needed)
MCP_REGISTRY_SEED_IMPORT=true ./registry

# Use different seed file
MCP_REGISTRY_SEED_FILE_PATH=/path/to/other/file.json ./registry
```

## 🎯 Summary

The MCP Registry is now running with:
- ✅ MongoDB for persistent storage
- ❌ **NO seed data import** from `data/seed_2025_05_16.json`
- ✅ Optional authorization working correctly
- ✅ Clean database (only manually published servers)
- ✅ Easy management with provided scripts
