#!/usr/bin/env bash
# Restart registry server with official MCP Registry configuration
#
# Usage:
#   ./restart-server.sh [config-name]
#
# Config options:
#   streamable-http  - HTTP only (17 servers) [default]
#   all-remote       - HTTP + SSE (26 servers)
#   all-servers      - All transports (30 servers)

set -e

WORKSPACE="/Users/rpalaniappan/github.com/stacklok/toolhive-registry-server"
CONFIG_NAME="${1:-streamable-http}"
CONFIG_DIR="$WORKSPACE/upstream-registry-setup"

# Validate config name
case "$CONFIG_NAME" in
    streamable-http)
        CONFIG_FILE="$CONFIG_DIR/config-streamable-http.yaml"
        REGISTRY_NAME="mcp-streamable-http"
        EXPECTED_COUNT="17"
        ;;
    all-remote)
        CONFIG_FILE="$CONFIG_DIR/config-all-remote.yaml"
        REGISTRY_NAME="mcp-remote"
        EXPECTED_COUNT="26"
        ;;
    all-servers)
        CONFIG_FILE="$CONFIG_DIR/config-all-servers.yaml"
        REGISTRY_NAME="mcp-all"
        EXPECTED_COUNT="30"
        ;;
    *)
        echo "❌ Invalid config name: $CONFIG_NAME"
        echo ""
        echo "Usage: $0 [streamable-http|all-remote|all-servers]"
        echo ""
        echo "Options:"
        echo "  streamable-http  - HTTP only (17 servers) [default]"
        echo "  all-remote       - HTTP + SSE (26 servers)"
        echo "  all-servers      - All transports (30 servers)"
        exit 1
        ;;
esac

echo "🔄 Restarting MCP Registry Server"
echo "Configuration: $CONFIG_NAME"
echo "=================================================="
echo ""

# Stop existing server
echo "🛑 Stopping existing server..."
if pkill -f thv-registry-api; then
    echo "   ✅ Server stopped"
else
    echo "   ℹ️  No running server found"
fi

echo ""
echo "⏳ Waiting for shutdown..."
sleep 3

# Start server
export THV_REGISTRY_ENABLE_AGGREGATED_ENDPOINTS=true
echo "🚀 Starting server with $CONFIG_NAME configuration..."
cd "$WORKSPACE"
nohup ./bin/thv-registry-api serve --config "$CONFIG_FILE" > server.log 2>&1 &
SERVER_PID=$!

echo "   ✅ Server started (PID: $SERVER_PID)"
echo ""
echo "⏳ Waiting for server to initialize..."
sleep 6

# Verify server
echo "🔍 Verifying server health..."
if curl -sf http://localhost:8080/health > /dev/null; then
    echo "   ✅ Server is healthy"
else
    echo "   ❌ Server health check failed"
    echo "   Check logs: tail -f $WORKSPACE/server.log"
    exit 1
fi

echo ""
echo "📊 Checking server count..."
SERVER_COUNT=$(curl -s http://localhost:8080/registry/$REGISTRY_NAME/v0.1/servers | jq '.servers | length' 2>/dev/null || echo "0")

if [ "$SERVER_COUNT" = "$EXPECTED_COUNT" ]; then
    echo "   ✅ Correct server count: $SERVER_COUNT"
elif [ "$SERVER_COUNT" = "0" ]; then
    echo "   ⏳ Servers still syncing... (current: $SERVER_COUNT)"
    echo "   Wait a moment and check again:"
    echo "   curl -s http://localhost:8080/registry/$REGISTRY_NAME/v0.1/servers | jq '.servers | length'"
else
    echo "   ⚠️  Server count: $SERVER_COUNT (expected: ~$EXPECTED_COUNT)"
    echo "   Sync may still be in progress"
fi

echo ""
echo "=================================================="
echo "✅ Registry Server Started Successfully"
echo "=================================================="
echo ""
echo "📍 Endpoints:"
echo "   List servers: http://localhost:8080/registry/$REGISTRY_NAME/v0.1/servers"
echo "   Registry status: http://localhost:8080/extension/v0/registries"
echo "   Health check: http://localhost:8080/health"
echo ""
echo "📝 Logs:"
echo "   tail -f $WORKSPACE/server.log"
echo ""
echo "🎯 Configuration: $CONFIG_NAME"
case "$CONFIG_NAME" in
    streamable-http)
        echo "   ✅ Streamable-HTTP servers: ~17"
        echo "   ❌ SSE servers: Excluded"
        echo "   ❌ stdio servers: Excluded"
        ;;
    all-remote)
        echo "   ✅ Streamable-HTTP servers: ~17"
        echo "   ✅ SSE servers: ~9"
        echo "   ❌ stdio servers: Excluded"
        ;;
    all-servers)
        echo "   ✅ All transports included"
        echo "   📊 Total: ~30 servers"
        ;;
esac
echo ""
echo "Test it:"
echo "   curl -s http://localhost:8080/registry/$REGISTRY_NAME/v0.1/servers | jq -r '.servers[].server.name'"
