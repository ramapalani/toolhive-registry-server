# Upstream Registry Setup - File Organization

All files related to the official MCP Registry setup have been consolidated into the `upstream-registry-setup/` folder.

## 📁 Folder Structure

```
upstream-registry-setup/
├── README.md                       # Consolidated guide (all-in-one)
├── config-streamable-http.yaml     # Option 1: HTTP only (17 servers)
├── config-all-remote.yaml          # Option 2: HTTP + SSE (26 servers)
├── config-all-servers.yaml         # Option 3: All transports (30 servers)
├── restart-server.sh               # Restart helper with config selection
└── analyze-transports.sh           # Transport analysis tool
```

## 🎯 What Changed

### Consolidated Documentation

**Before:** 5 separate markdown files scattered in root
- QUICKSTART-UPSTREAM.md
- ACCESSING-THE-API.md
- STREAMABLE-HTTP-ONLY.md
- QUICK-RESTART-GUIDE.md
- README-UPDATES.md

**After:** 1 comprehensive guide
- `upstream-registry-setup/README.md` - Contains everything

### Organized Configuration

**Before:** Config files in `examples/` mixed with other examples

**After:** Dedicated folder with clear naming
- `config-streamable-http.yaml` - HTTP only
- `config-all-remote.yaml` - HTTP + SSE
- `config-all-servers.yaml` - All transports

### Helper Scripts

**Before:** Scripts in root and `scripts/` folder

**After:** All tools in `upstream-registry-setup/`
- `restart-server.sh` - Enhanced with config selection
- `analyze-transports.sh` - Transport analysis

## 🚀 Quick Start

### Option 1: HTTP Only (Recommended)

```bash
cd /Users/rpalaniappan/github.com/stacklok/toolhive-registry-server
./bin/thv-registry-api serve --config upstream-registry-setup/config-streamable-http.yaml
```

### Option 2: HTTP + SSE

```bash
./bin/thv-registry-api serve --config upstream-registry-setup/config-all-remote.yaml
```

### Option 3: All Transports

```bash
./bin/thv-registry-api serve --config upstream-registry-setup/config-all-servers.yaml
```

### Using the Restart Script

```bash
# Default: streamable-http
./upstream-registry-setup/restart-server.sh

# Specify configuration
./upstream-registry-setup/restart-server.sh streamable-http
./upstream-registry-setup/restart-server.sh all-remote
./upstream-registry-setup/restart-server.sh all-servers
```

## 📖 Documentation

Everything you need is in one place:

```bash
# Read the complete guide
cat upstream-registry-setup/README.md

# Or open in your editor
code upstream-registry-setup/README.md
```

The consolidated guide includes:
- ✅ Quick start for all 3 options
- ✅ Transport type explanations
- ✅ Configuration details
- ✅ API access guide
- ✅ Transport filtering
- ✅ Production deployment
- ✅ Troubleshooting
- ✅ Quick reference

## 🔧 Helper Tools

### Analyze Transports

```bash
cd upstream-registry-setup
./analyze-transports.sh
```

### Restart Server

```bash
cd upstream-registry-setup
./restart-server.sh [streamable-http|all-remote|all-servers]
```

## ✨ Benefits of New Organization

1. **Single Location**: Everything related to upstream registry in one folder
2. **No Root Clutter**: Clean root directory
3. **Consolidated Docs**: One comprehensive guide instead of 5 separate files
4. **Clear Naming**: Config files clearly indicate what they do
5. **Self-Contained**: Folder can be copied/shared independently

## 📋 Configuration Summary

| File | Servers | Transports | Use Case |
|------|---------|------------|----------|
| config-streamable-http.yaml | 17 | HTTP only | Kubernetes, HTTP-only infra |
| config-all-remote.yaml | 26 | HTTP + SSE | Remote with SSE support |
| config-all-servers.yaml | 30 | All | Complete mirror |

## 🗑️ Cleaned Up

The following redundant files were removed from the root directory:
- ❌ QUICKSTART-UPSTREAM.md
- ❌ ACCESSING-THE-API.md
- ❌ STREAMABLE-HTTP-ONLY.md
- ❌ QUICK-RESTART-GUIDE.md
- ❌ README-UPDATES.md
- ❌ restart-server.sh

All content consolidated into `upstream-registry-setup/README.md`

## 🔗 Links in Main Documentation

Main README and examples/README have been updated to point to:
```
upstream-registry-setup/README.md
```

## 📝 Note

The original example configs in `examples/` folder remain unchanged for backwards compatibility, but the recommended location is now `upstream-registry-setup/`.

---

**Everything you need for official MCP Registry setup is now in one organized folder!** 🎉
