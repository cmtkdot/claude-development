#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PLUGIN_DIR="/Users/jay/development/claude-development"
MARKETPLACE_ROOT="/Users/jay/development/claude-mem"
MARKETPLACE_JSON="$MARKETPLACE_ROOT/.claude-plugin/marketplace.json"
PLUGIN_NAME="plugin-dev"
SYMLINK_PATH="$MARKETPLACE_ROOT/$PLUGIN_NAME"

# ─── COLORS ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# ─── CREATE/UPDATE SYMLINK ──────────────────────────────────────────────────
log "Ensuring symlink exists..."
if [[ -L "$SYMLINK_PATH" ]]; then
    CURRENT_TARGET=$(readlink "$SYMLINK_PATH")
    if [[ "$CURRENT_TARGET" != "$PLUGIN_DIR" ]]; then
        rm "$SYMLINK_PATH"
        ln -s "$PLUGIN_DIR" "$SYMLINK_PATH"
        success "Updated symlink to $PLUGIN_DIR"
    else
        success "Symlink already correct"
    fi
elif [[ -e "$SYMLINK_PATH" ]]; then
    error "Path exists but is not a symlink: $SYMLINK_PATH"
else
    ln -s "$PLUGIN_DIR" "$SYMLINK_PATH"
    success "Created symlink: $SYMLINK_PATH -> $PLUGIN_DIR"
fi

# ─── UPDATE MARKETPLACE ─────────────────────────────────────────────────────
log "Updating marketplace.json..."

# Check if plugin already exists in marketplace
if jq -e ".plugins[] | select(.name == \"$PLUGIN_NAME\")" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
    log "Updating existing plugin entry..."
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg desc "$PLUGIN_DESC" \
       '(.plugins[] | select(.name == $name)) |= {
           name: $name,
           version: $version,
           source: ("./" + $name),
           description: $desc
       }' "$MARKETPLACE_JSON" > /tmp/marketplace.json
    mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    success "Updated $PLUGIN_NAME to v$PLUGIN_VERSION"
else
    log "Adding new plugin entry..."
    jq --arg name "$PLUGIN_NAME" \
       --arg version "$PLUGIN_VERSION" \
       --arg desc "$PLUGIN_DESC" \
       '.plugins += [{
           name: $name,
           version: $version,
           source: ("./" + $name),
           description: $desc
       }]' "$MARKETPLACE_JSON" > /tmp/marketplace.json
    mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    success "Added $PLUGIN_NAME v$PLUGIN_VERSION to marketplace"
fi

# ─── REFRESH MARKETPLACE ────────────────────────────────────────────────────
log "Refreshing cmtkdot marketplace..."
if claude plugin marketplace update cmtkdot 2>/dev/null; then
    success "Marketplace refreshed"
else
    warn "Marketplace refresh failed - may need manual update"
fi

# ─── ENSURE PLUGIN ENABLED ──────────────────────────────────────────────────
log "Ensuring plugin is enabled..."
SETTINGS_FILE="$HOME/.claude/settings.json"

if ! jq -e ".enabledPlugins[\"$PLUGIN_NAME@cmtkdot\"]" "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq ".enabledPlugins[\"$PLUGIN_NAME@cmtkdot\"] = true" "$SETTINGS_FILE" > /tmp/settings.json
    mv /tmp/settings.json "$SETTINGS_FILE"
    success "Enabled $PLUGIN_NAME@cmtkdot"
else
    success "Plugin already enabled"
fi

# ─── GIT SYNC ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--push" ]]; then
    log "Pushing changes to git..."

    cd "$PLUGIN_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "chore: sync v$PLUGIN_VERSION"
        git push
        success "Pushed plugin-dev changes"
    else
        log "No changes in plugin-dev"
    fi

    cd "$MARKETPLACE_ROOT"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "chore: update plugin-dev to v$PLUGIN_VERSION"
        git push
        success "Pushed marketplace changes"
    else
        log "No changes in marketplace"
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
echo "  Symlink:     $SYMLINK_PATH -> $PLUGIN_DIR"
echo ""
echo "  Restart Claude Code to apply changes."
echo ""
echo "  To push git changes:"
echo "    $0 --push"
echo ""
