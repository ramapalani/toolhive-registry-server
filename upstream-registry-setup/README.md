# Official MCP Registry Setup Guide

Complete guide for configuring ToolHive Registry Server to sync from the official MCP Registry (https://registry.modelcontextprotocol.io/) with transport filtering.

## Table of Contents

- [Quick Start](#quick-start)
- [Transport Types](#transport-types)
- [Configuration Options](#configuration-options)
- [Accessing the API](#accessing-the-api)
- [Transport Filtering](#transport-filtering)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Built `thv-registry-api` binary: `go build -o bin/thv-registry-api ./cmd/thv-registry-api`

### Option 1: Streamable-HTTP Only (Recommended for Remote Deployment)

Pull only HTTP streaming servers, excluding SSE and stdio:

```bash
# Start the server
./bin/thv-registry-api serve --config upstream-registry-setup/config-streamable-http.yaml

# Verify (should show 17 servers)
curl -s http://localhost:8080/registry/mcp-streamable-http/v0.1/servers | jq '.servers | length'

# List servers
curl -s http://localhost:8080/registry/mcp-streamable-http/v0.1/servers | \
  jq -r '.servers[].server.name'
```

### Option 2: All Remote Servers (HTTP + SSE)

Include both HTTP and SSE servers, exclude only stdio:

```bash
# Start the server
./bin/thv-registry-api serve --config upstream-registry-setup/config-all-remote.yaml

# Verify (should show ~26 servers)
curl -s http://localhost:8080/registry/mcp-remote/v0.1/servers | jq '.servers | length'
```

### Option 3: All Servers (No Filter)

Include everything - HTTP, SSE, and stdio:

```bash
# Start the server
./bin/thv-registry-api serve --config upstream-registry-setup/config-all-servers.yaml

# Verify (should show ~30 servers)
curl -s http://localhost:8080/registry/mcp-all/v0.1/servers | jq '.servers | length'
```

---

## Transport Types

MCP servers use three different transport mechanisms:

### Comparison Table

| Transport | Type | Use Case | Remote? | Included |
|-----------|------|----------|---------|----------|
| **stdio** | Standard I/O | Local process communication | ❌ No | Option 3 only |
| **sse** | Server-Sent Events | Remote event streaming | ✅ Yes | Options 2 & 3 |
| **streamable-http** | HTTP streaming | Remote HTTP API | ✅ Yes | All options ✅ |

### When to Use Each Configuration

**Option 1 - Streamable-HTTP Only (17 servers)**
- ✅ Kubernetes deployments
- ✅ HTTP-only infrastructure
- ✅ Maximum compatibility
- ✅ Simplest remote deployment

**Option 2 - All Remote (26 servers)**
- ✅ Support both HTTP and SSE
- ✅ More server options
- ⚠️ Requires SSE support in infrastructure

**Option 3 - All Servers (30 servers)**
- ✅ Complete registry mirror
- ❌ Includes local-only stdio servers
- ⚠️ Not all servers are remotely accessible

---

## Configuration Options

### Streamable-HTTP Only Configuration

**File:** `config-streamable-http.yaml`

```yaml
registryName: mcp-streamable-http-registry

registries:
  - name: mcp-streamable-http
    format: upstream
    api:
      endpoint: https://registry.modelcontextprotocol.io
    syncPolicy:
      interval: "1h"
    filter:
      names:
        include:
          - "ai.alpic.test/test-mcp-server"
          - "ai.cirra/salesforce-mcp"
          - "ai.com.mcp/*"
          - "ai.exa/exa"
          - "ai.explorium/mcp-explorium"
          - "ai.filegraph/document-processing"
          - "ai.gossiper/shopify-admin-mcp"
          - "ai.klavis/strata"
          - "ai.kubit/mcp-server"
          - "ai.llmse/mcp"
          - "ai.ludo/game-assets"
        exclude:
          - "ai.gomarble/mcp-api"  # SSE only

auth:
  mode: anonymous

fileStorage:
  baseDir: ./data/mcp-streamable-http
```

**Result:** 17 streamable-http servers

### All Remote Servers Configuration

**File:** `config-all-remote.yaml`

```yaml
registryName: mcp-remote-registry

registries:
  - name: mcp-remote
    format: upstream
    api:
      endpoint: https://registry.modelcontextprotocol.io
    syncPolicy:
      interval: "1h"
    filter:
      names:
        include:
          # All servers with remotes (HTTP or SSE)
          - "ai.alpic.test/*"
          - "ai.cirra/*"
          - "ai.com.mcp/*"
          - "ai.exa/*"
          - "ai.explorium/*"
          - "ai.filegraph/*"
          - "ai.gomarble/*"
          - "ai.gossiper/*"
          - "ai.klavis/*"
          - "ai.kubit/*"
          - "ai.llmse/*"
          - "ai.ludo/*"

auth:
  mode: anonymous

fileStorage:
  baseDir: ./data/mcp-remote
```

**Result:** ~26 servers (HTTP + SSE)

### All Servers Configuration

**File:** `config-all-servers.yaml`

```yaml
registryName: mcp-all-registry

registries:
  - name: mcp-all
    format: upstream
    api:
      endpoint: https://registry.modelcontextprotocol.io
    syncPolicy:
      interval: "1h"
    # No filter - include everything

auth:
  mode: anonymous

fileStorage:
  baseDir: ./data/mcp-all
```

**Result:** ~30 servers (all transports)

---

## Accessing the API

### Important: Per-Registry Endpoints

The aggregated endpoints (`/registry/v0.1/servers`) require enabling via environment variable.

**Use per-registry endpoints instead** (works immediately):

```bash
# Replace {registry-name} with your registry name:
# - mcp-streamable-http (Option 1)
# - mcp-remote (Option 2)
# - mcp-all (Option 3)

# List all servers
curl http://localhost:8080/registry/{registry-name}/v0.1/servers | jq

# Get server count
curl -s http://localhost:8080/registry/{registry-name}/v0.1/servers | \
  jq '.servers | length'

# List server names
curl -s http://localhost:8080/registry/{registry-name}/v0.1/servers | \
  jq -r '.servers[].server.name'

# Get server versions
curl http://localhost:8080/registry/{registry-name}/v0.1/servers/{name}/versions | jq

# Get specific version
curl http://localhost:8080/registry/{registry-name}/v0.1/servers/{name}/versions/{version} | jq
```

### Common Queries

**Filter by transport type:**

```bash
# Get only SSE servers
curl -s http://localhost:8080/registry/mcp-remote/v0.1/servers | \
  jq '.servers[] | select(.server.remotes[0].type == "sse") | .server.name'

# Get only streamable-http servers
curl -s http://localhost:8080/registry/mcp-remote/v0.1/servers | \
  jq '.servers[] | select(.server.remotes[0].type == "streamable-http") | .server.name'
```

**Get servers with details:**

```bash
curl -s http://localhost:8080/registry/mcp-streamable-http/v0.1/servers | \
  jq '.servers[] | {
    name: .server.name,
    description: .server.description,
    version: .server.version,
    transport: .server.remotes[0].type,
    url: .server.remotes[0].url
  }'
```

**Export to CSV:**

```bash
curl -s http://localhost:8080/registry/mcp-streamable-http/v0.1/servers | \
  jq -r '.servers[] | 
    [.server.name, .server.version, .server.remotes[0].type, .server.remotes[0].url] | 
    @csv' > servers.csv
```

### Registry Status

```bash
# List all registries
curl http://localhost:8080/extension/v0/registries | jq

# Get specific registry status
curl http://localhost:8080/extension/v0/registries/{registry-name} | jq
```

---

## Transport Filtering

### Analyzing Transports

Use the included script to analyze server transports from the official registry:

```bash
# Run analysis
./scripts/analyze-transports.sh

# View results
cat ./data/analysis/transport-report.md

# View HTTP/SSE servers
cat ./data/analysis/http-sse-servers.txt

# View stdio servers
cat ./data/analysis/stdio-servers.txt
```

The script outputs:
- Total server count
- Breakdown by transport type
- List of servers for each transport
- Markdown report with statistics

### Creating Custom Filters

To create your own filtered configuration:

**Step 1: Analyze**
```bash
./scripts/analyze-transports.sh
cat ./data/analysis/http-sse-servers.txt
```

**Step 2: Create config**
```yaml
filter:
  names:
    include:
      - "server1/name"
      - "server2/name"
    exclude:
      - "unwanted/server"
```

**Step 3: Test**
```bash
./bin/thv-registry-api serve --config your-config.yaml

# Verify transport types
curl -s http://localhost:8080/registry/your-registry/v0.1/servers | \
  jq -r '[.servers[].server.remotes[0].type] | unique'
```

---

## Production Deployment

### With PostgreSQL Database

**1. Set up PostgreSQL:**

```bash
# Create database and users
createdb registry
psql -d registry -c "CREATE USER db_app WITH PASSWORD 'app_pass';"
psql -d registry -c "CREATE USER db_migrator WITH PASSWORD 'migrator_pass';"
```

**2. Configure credentials (.pgpass):**

```bash
echo "localhost:5432:registry:db_app:app_pass" >> ~/.pgpass
echo "localhost:5432:registry:db_migrator:migrator_pass" >> ~/.pgpass
chmod 600 ~/.pgpass
```

**3. Update configuration:**

```yaml
database:
  host: localhost
  port: 5432
  user: db_app
  migrationUser: db_migrator
  database: registry
  sslMode: require  # Use require or verify-full in production
  maxOpenConns: 25
  maxIdleConns: 5
  connMaxLifetime: "1h"
```

**4. Run migrations:**

```bash
./bin/thv-registry-api migrate up --config upstream-registry-setup/config-streamable-http.yaml
```

**5. Start server:**

```bash
./bin/thv-registry-api serve --config upstream-registry-setup/config-streamable-http.yaml
```

### With Docker Compose

See main [Docker deployment guide](../docs/deployment-docker.md) for details.

### With OAuth Authentication

Update configuration:

```yaml
auth:
  mode: oauth
  oauth:
    resourceUrl: https://registry.example.com
    providers:
      - name: company-sso
        issuerUrl: https://auth.example.com
        audience: api://registry
```

See [Authentication guide](../docs/authentication.md) for complete setup.

---

## Troubleshooting

### Issue: 404 Not Found

**Symptom:** `/registry/v0.1/servers` returns 404

**Solution:** Use per-registry endpoint:
```bash
# Wrong
curl http://localhost:8080/registry/v0.1/servers

# Correct
curl http://localhost:8080/registry/mcp-streamable-http/v0.1/servers
```

Or enable aggregated endpoints:
```bash
export THV_REGISTRY_ENABLE_AGGREGATED_ENDPOINTS=true
# Restart server
```

### Issue: Wrong Server Count

**Problem:** Expected 17 but got 26

**Solution:** Check you're using the correct config:
```bash
# Verify config file
cat upstream-registry-setup/config-streamable-http.yaml | grep "exclude"

# Check loaded registry name
curl http://localhost:8080/extension/v0/registries | jq '.registries[].name'
```

### Issue: Sync Not Working

**Check sync status:**
```bash
curl http://localhost:8080/extension/v0/registries/mcp-streamable-http | jq
```

**Look for:**
- `last_sync_time`: When last sync completed
- `sync_status`: Should be "success"
- `total_servers`: Should be > 0

**Common causes:**
- Network connectivity to https://registry.modelcontextprotocol.io
- Invalid filter patterns
- Incorrect config file path

### Issue: Server Not in List

**1. Check if server has required transport:**
```bash
./scripts/analyze-transports.sh
grep "server-name" ./data/analysis/http-sse-servers.txt
```

**2. If found, add to filter:**
```yaml
filter:
  names:
    include:
      - "your/server-name"
```

**3. Restart server and verify:**
```bash
./restart-server.sh
curl -s http://localhost:8080/registry/mcp-streamable-http/v0.1/servers | \
  grep "server-name"
```

---

## Quick Reference

### Server Counts

| Configuration | Servers | Transports |
|--------------|---------|------------|
| Streamable-HTTP only | 17 | HTTP |
| All remote | 26 | HTTP + SSE |
| All servers | 30 | HTTP + SSE + stdio |

### Streamable-HTTP Servers (17)

1. ai.alpic.test/test-mcp-server
2. ai.cirra/salesforce-mcp
3. ai.com.mcp/contabo
4. ai.com.mcp/hapi-mcp
5. ai.com.mcp/lenny-rachitsky-podcast
6. ai.com.mcp/openai-tools
7. ai.com.mcp/petstore
8. ai.com.mcp/registry
9. ai.com.mcp/skills-search
10. ai.exa/exa
11. ai.explorium/mcp-explorium
12. ai.filegraph/document-processing
13. ai.gossiper/shopify-admin-mcp
14. ai.klavis/strata
15. ai.kubit/mcp-server
16. ai.llmse/mcp
17. ai.ludo/game-assets

### Key Endpoints

```bash
# List servers
GET /registry/{registry-name}/v0.1/servers

# Get versions
GET /registry/{registry-name}/v0.1/servers/{name}/versions

# Get specific version
GET /registry/{registry-name}/v0.1/servers/{name}/versions/{version}

# Registry status
GET /extension/v0/registries

# Health check
GET /health
```

### Helper Scripts

```bash
# Analyze transports
./scripts/analyze-transports.sh

# Restart server
./restart-server.sh
```

---

## Additional Resources

- [Main README](../README.md) - Project overview
- [Configuration Guide](../docs/configuration.md) - All config options
- [Database Setup](../docs/database.md) - PostgreSQL configuration
- [Authentication](../docs/authentication.md) - OAuth setup
- [Kubernetes Deployment](../docs/deployment-kubernetes.md) - K8s guide
- [Examples](../examples/README.md) - More configuration examples

---

## Summary

You now have three configuration options for syncing from the official MCP Registry:

1. ✅ **Streamable-HTTP only** (17 servers) - Recommended for remote deployment
2. ✅ **All remote** (26 servers) - HTTP + SSE
3. ✅ **All servers** (30 servers) - Complete mirror

Choose based on your infrastructure requirements and transport support!
