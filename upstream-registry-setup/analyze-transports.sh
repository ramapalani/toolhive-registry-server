#!/usr/bin/env bash
# Helper script to identify MCP servers with HTTP/SSE transport from the official registry
#
# This script fetches server data from the official MCP Registry and identifies
# which servers support remote HTTP/SSE transports (streamable-http, sse) vs
# local stdio transport.
#
# Usage:
#   chmod +x scripts/analyze-transports.sh
#   ./scripts/analyze-transports.sh

set -euo pipefail

API_URL="https://registry.modelcontextprotocol.io/v0.1/servers"
OUTPUT_DIR="./data/analysis"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Fetching server list from official MCP Registry..."
mkdir -p "$OUTPUT_DIR"

# Fetch the server list
SERVERS_JSON=$(curl -s "$API_URL")

# Count total servers
TOTAL_SERVERS=$(echo "$SERVERS_JSON" | jq '.servers | length')
echo -e "${BLUE}Total servers: $TOTAL_SERVERS${NC}"
echo ""

# Initialize counters
HTTP_COUNT=0
SSE_COUNT=0
STDIO_COUNT=0

# Files to store results
HTTP_SERVERS="$OUTPUT_DIR/http-sse-servers.txt"
STDIO_SERVERS="$OUTPUT_DIR/stdio-servers.txt"
TRANSPORT_REPORT="$OUTPUT_DIR/transport-report.md"

> "$HTTP_SERVERS"
> "$STDIO_SERVERS"
> "$TRANSPORT_REPORT"

# Write report header
cat > "$TRANSPORT_REPORT" <<EOF
# MCP Registry Transport Analysis

Analysis of transport types in the official MCP Registry (${API_URL})

**Generated:** $(date)
**Total Servers:** ${TOTAL_SERVERS}

## Summary

EOF

echo -e "${GREEN}Analyzing transport types...${NC}"
echo ""

# Process each server
echo "$SERVERS_JSON" | jq -r '.servers[] | @base64' | while read -r server_b64; do
  server=$(echo "$server_b64" | base64 -d)
  
  name=$(echo "$server" | jq -r '.server.name')
  
  # Get all transport types from packages and remotes
  transports=$(echo "$server" | jq -r '
    [
      (.server.packages[]?.transport?.type // empty),
      (.server.remotes[]?.type // empty)
    ] | unique | .[]
  ')
  
  has_http=false
  has_sse=false
  has_stdio=false
  
  while IFS= read -r transport; do
    case "$transport" in
      "streamable-http")
        has_http=true
        ;;
      "sse")
        has_sse=true
        ;;
      "stdio")
        has_stdio=true
        ;;
    esac
  done <<< "$transports"
  
  # Categorize server
  if [ "$has_http" = true ] || [ "$has_sse" = true ]; then
    HTTP_COUNT=$((HTTP_COUNT + 1))
    echo "$name" >> "$HTTP_SERVERS"
    
    transport_type="streamable-http"
    [ "$has_sse" = true ] && transport_type="sse"
    
    echo -e "  ${GREEN}✓${NC} $name (${transport_type})"
  elif [ "$has_stdio" = true ]; then
    STDIO_COUNT=$((STDIO_COUNT + 1))
    echo "$name" >> "$STDIO_SERVERS"
    echo -e "  ${YELLOW}○${NC} $name (stdio)"
  fi
done

# Write summary to report
cat >> "$TRANSPORT_REPORT" <<EOF
| Transport Type | Count | Percentage |
|---------------|-------|------------|
| HTTP/SSE (Remote) | ${HTTP_COUNT} | $(awk "BEGIN {printf \"%.1f\", ${HTTP_COUNT}/${TOTAL_SERVERS}*100}")% |
| stdio (Local) | ${STDIO_COUNT} | $(awk "BEGIN {printf \"%.1f\", ${STDIO_COUNT}/${TOTAL_SERVERS}*100}")% |

## Remote HTTP/SSE Servers

These servers can be accessed over HTTP and are suitable for remote deployment:

EOF

# Add HTTP/SSE servers to report
if [ -f "$HTTP_SERVERS" ] && [ -s "$HTTP_SERVERS" ]; then
  while IFS= read -r server_name; do
    echo "- \`$server_name\`" >> "$TRANSPORT_REPORT"
  done < "$HTTP_SERVERS"
fi

# Add stdio section
cat >> "$TRANSPORT_REPORT" <<EOF

## Local stdio Servers

These servers use stdio transport and typically run as local processes:

EOF

if [ -f "$STDIO_SERVERS" ] && [ -s "$STDIO_SERVERS" ]; then
  while IFS= read -r server_name; do
    echo "- \`$server_name\`" >> "$TRANSPORT_REPORT"
  done < "$STDIO_SERVERS"
fi

# Print summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Analysis Complete${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo "Results saved to:"
echo "  - HTTP/SSE servers: $HTTP_SERVERS"
echo "  - stdio servers:    $STDIO_SERVERS"
echo "  - Full report:      $TRANSPORT_REPORT"
echo ""
echo "Summary:"
echo "  Total servers:      $TOTAL_SERVERS"
echo "  HTTP/SSE (Remote):  $HTTP_COUNT"
echo "  stdio (Local):      $STDIO_COUNT"
echo ""
echo -e "${GREEN}To use only HTTP/SSE servers, add these server names to your filter config:${NC}"
echo ""
echo "filter:"
echo "  names:"
echo "    include:"
cat "$HTTP_SERVERS" | sed 's/^/      - "/' | sed 's/$/"/'
