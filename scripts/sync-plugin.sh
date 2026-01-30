#!/bin/bash
# Sync local plugin to global Claude plugins cache

set -e

PLUGIN_NAME="claude-toolkit"
MARKETPLACE="claude-toolkit"
VERSION="1.0.0"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$HOME/.claude/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$VERSION"
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get current git commit
get_commit_sha() {
    git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo "unknown"
}

# Get cached commit from installed_plugins.json
get_cached_sha() {
    if [[ -f "$INSTALLED_JSON" ]]; then
        grep -A10 "\"$PLUGIN_NAME@$MARKETPLACE\"" "$INSTALLED_JSON" | grep "gitCommitSha" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'
    fi
}

# Check mode - just show status
if [[ "$1" == "--check" ]]; then
    CURRENT=$(get_commit_sha)
    CACHED=$(get_cached_sha)

    echo -e "${BLUE}Plugin:${NC} $PLUGIN_NAME@$MARKETPLACE"
    echo -e "${BLUE}Current commit:${NC} ${CURRENT:0:7}"
    echo -e "${BLUE}Cached commit:${NC}  ${CACHED:0:7}"

    if [[ "$CURRENT" == "$CACHED" ]]; then
        echo -e "${GREEN}✓ Plugin is up to date${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Plugin needs sync (run: npm run sync)${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Syncing $PLUGIN_NAME to global plugins...${NC}"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Sync .claude-plugin contents to cache
echo "  Copying plugin files..."
rsync -av --delete \
    --exclude '.DS_Store' \
    --exclude '*.pyc' \
    --exclude '__pycache__' \
    --exclude '.git' \
    "$SOURCE_DIR/.claude-plugin/" "$CACHE_DIR/"

# Get current commit SHA
COMMIT_SHA=$(get_commit_sha)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Update installed_plugins.json
if [[ -f "$INSTALLED_JSON" ]]; then
    echo "  Updating installed_plugins.json..."

    # Create temp file with updated entry
    python3 << EOF
import json
from datetime import datetime

with open("$INSTALLED_JSON", "r") as f:
    data = json.load(f)

key = "$PLUGIN_NAME@$MARKETPLACE"
data["plugins"][key] = [{
    "scope": "user",
    "installPath": "$CACHE_DIR",
    "version": "$VERSION",
    "installedAt": data["plugins"].get(key, [{}])[0].get("installedAt", "$TIMESTAMP"),
    "lastUpdated": "$TIMESTAMP",
    "gitCommitSha": "$COMMIT_SHA"
}]

with open("$INSTALLED_JSON", "w") as f:
    json.dump(data, f, indent=2)
EOF
fi

echo -e "${GREEN}✓ Synced to $CACHE_DIR${NC}"
echo -e "${GREEN}✓ Updated installed_plugins.json (commit: ${COMMIT_SHA:0:7})${NC}"
echo ""
echo -e "${YELLOW}Note: Restart Claude Code to load changes${NC}"
