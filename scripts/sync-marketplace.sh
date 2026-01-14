#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PLUGIN_DIR="/Users/jay/development/claude-development"
MARKETPLACE_DIR="/Users/jay/development/claude-mem/.claude-plugin"
MARKETPLACE_JSON="$MARKETPLACE_DIR/marketplace.json"
PLUGIN_NAME="plugin-dev"

# ─── COLORS ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[sync]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ─── VALIDATE ───────────────────────────────────────────────────────────────
log "Validating plugin..."
if ! claude plugin validate "$PLUGIN_DIR" 2>/dev/null; then
    error "Plugin validation failed"
fi
success "Plugin validation passed"

# ─── GET PLUGIN VERSION ─────────────────────────────────────────────────────
PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")
PLUGIN_DESC=$(jq -r '.description' "$PLUGIN_DIR/.claude-plugin/plugin.json")
log "Plugin version: $PLUGIN_VERSION"

# ─── UPDATE MARKETPLACE ─────────────────────────────────────────────────────
log "Updating marketplace.json..."

# Check if plugin already exists in marketplace
if jq -e ".plugins[] | select(.name == \"$PLUGIN_NAME\")" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
    # Update existing plugin
    log "Updating existing plugin entry..."
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg source "$PLUGIN_DIR" \
       --arg desc "$PLUGIN_DESC" \
       '(.plugins[] | select(.name == $name)) |= {
           name: $name,
           version: $version,
           source: { source: "directory", path: $source },
           description: $desc
       }' "$MARKETPLACE_JSON" > /tmp/marketplace.json
    mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    success "Updated plugin-dev to v$PLUGIN_VERSION"
else
    # Add new plugin
    log "Adding new plugin entry..."
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg source "$PLUGIN_DIR" \
       --arg desc "$PLUGIN_DESC" \
       '.plugins += [{
           name: $name,
           version: $version,
           source: { source: "directory", path: $source },
           description: $desc
       }]' "$MARKETPLACE_JSON" > /tmp/marketplace.json
    mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    success "Added plugin-dev v$PLUGIN_VERSION to marketplace"
fi

# ─── UPDATE USER SETTINGS ───────────────────────────────────────────────────
log "Ensuring plugin is enabled in user settings..."
SETTINGS_FILE="$HOME/.claude/settings.json"

# Add to enabledPlugins if not present
if ! jq -e ".enabledPlugins[\"$PLUGIN_NAME@cmtkdot\"]" "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq ".enabledPlugins[\"$PLUGIN_NAME@cmtkdot\"] = true" "$SETTINGS_FILE" > /tmp/settings.json
    mv /tmp/settings.json "$SETTINGS_FILE"
    success "Enabled plugin-dev@cmtkdot in settings"
else
    success "Plugin already enabled"
fi

# ─── GIT SYNC (optional) ────────────────────────────────────────────────────
if [[ "${1:-}" == "--push" ]]; then
    log "Pushing changes to git..."

    # Push plugin repo
    cd "$PLUGIN_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "chore: sync marketplace v$PLUGIN_VERSION"
        git push
        success "Pushed plugin-dev changes"
    else
        log "No changes to push in plugin-dev"
    fi

    # Push marketplace repo
    cd "$MARKETPLACE_DIR/.."
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "chore: update plugin-dev to v$PLUGIN_VERSION"
        git push
        success "Pushed marketplace changes"
    else
        log "No changes to push in marketplace"
    fi
fi

# ─── SUMMARY ────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Marketplace sync complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Plugin:      $PLUGIN_NAME v$PLUGIN_VERSION"
echo "  Marketplace: cmtkdot"
echo "  Location:    $MARKETPLACE_JSON"
echo ""
echo "  To apply changes, restart Claude Code or run:"
echo "    claude --plugin-dir $PLUGIN_DIR"
echo ""
echo "  To push git changes:"
echo "    $0 --push"
echo ""
