#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ─────────────────────────────────────────────────────────────────
PLUGIN_NAME="plugin-dev"
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_NAME="cmtkdot"
MARKETPLACE_ROOT="/Users/jay/development/claude-mem"
MARKETPLACE_JSON="$MARKETPLACE_ROOT/.claude-plugin/marketplace.json"

# ─── COLORS ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[$PLUGIN_NAME]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ─── VERSION BUMP ───────────────────────────────────────────────────────────
bump_version() {
    local bump_type="${1:-patch}"
    local current=$(jq -r '.version' "$PLUGIN_JSON")

    IFS='.' read -r major minor patch <<< "$current"

    case "$bump_type" in
        major) ((major++)); minor=0; patch=0 ;;
        minor) ((minor++)); patch=0 ;;
        patch) ((patch++)) ;;
        *) error "Unknown bump type: $bump_type (use major, minor, or patch)" ;;
    esac

    local new_version="$major.$minor.$patch"

    jq --arg v "$new_version" '.version = $v' "$PLUGIN_JSON" > /tmp/plugin.json
    mv /tmp/plugin.json "$PLUGIN_JSON"

    success "Version bumped: $current → $new_version"
    echo "$new_version"
}

# ─── VALIDATE ───────────────────────────────────────────────────────────────
validate() {
    log "Validating plugin..."
    if claude plugin validate "$PLUGIN_DIR" 2>/dev/null; then
        success "Validation passed"
    else
        error "Validation failed"
    fi
}

# ─── SYNC TO MARKETPLACE ────────────────────────────────────────────────────
sync_marketplace() {
    log "Syncing to $MARKETPLACE_NAME marketplace..."

    local version=$(jq -r '.version' "$PLUGIN_JSON")
    local desc=$(jq -r '.description' "$PLUGIN_JSON")

    # Ensure symlink exists
    local symlink_path="$MARKETPLACE_ROOT/$PLUGIN_NAME"
    if [[ ! -L "$symlink_path" ]]; then
        if [[ -e "$symlink_path" ]]; then
            error "Path exists but is not a symlink: $symlink_path"
        fi
        ln -s "$PLUGIN_DIR" "$symlink_path"
        success "Created symlink"
    fi

    # Update marketplace.json
    if jq -e ".plugins[] | select(.name == \"$PLUGIN_NAME\")" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
        jq --arg name "$PLUGIN_NAME" \
           --arg version "$version" \
           --arg desc "$desc" \
           '(.plugins[] | select(.name == $name)) |= {
               name: $name,
               version: $version,
               source: ("./" + $name),
               description: $desc
           }' "$MARKETPLACE_JSON" > /tmp/marketplace.json
        mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    else
        jq --arg name "$PLUGIN_NAME" \
           --arg version "$version" \
           --arg desc "$desc" \
           '.plugins += [{
               name: $name,
               version: $version,
               source: ("./" + $name),
               description: $desc
           }]' "$MARKETPLACE_JSON" > /tmp/marketplace.json
        mv /tmp/marketplace.json "$MARKETPLACE_JSON"
    fi

    success "Updated marketplace.json (v$version)"

    # Refresh marketplace
    if claude plugin marketplace update "$MARKETPLACE_NAME" 2>/dev/null; then
        success "Marketplace refreshed"
    else
        warn "Marketplace refresh failed - may need manual update"
    fi
}

# ─── UPDATE INSTALLED ───────────────────────────────────────────────────────
update_installed() {
    log "Updating installed plugin..."

    local key="${PLUGIN_NAME}@${MARKETPLACE_NAME}"

    if claude plugin update "$key" 2>/dev/null; then
        success "Plugin updated"
    else
        log "Trying fresh install..."
        if claude plugin install "$key" --scope user 2>/dev/null; then
            success "Plugin installed"
        else
            warn "Update failed - restart Claude Code and try again"
        fi
    fi
}

# ─── GIT OPERATIONS ─────────────────────────────────────────────────────────
git_commit() {
    local version=$(jq -r '.version' "$PLUGIN_JSON")
    local message="${1:-chore: release v$version}"

    cd "$PLUGIN_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "$message"
        success "Committed: $message"
    else
        log "No changes to commit"
    fi
}

git_push() {
    cd "$PLUGIN_DIR"
    git push
    success "Pushed to remote"

    # Also push marketplace changes
    cd "$MARKETPLACE_ROOT"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "chore: update $PLUGIN_NAME"
        git push
        success "Pushed marketplace changes"
    fi
}

git_tag() {
    local version=$(jq -r '.version' "$PLUGIN_JSON")
    cd "$PLUGIN_DIR"

    if git rev-parse "v$version" >/dev/null 2>&1; then
        warn "Tag v$version already exists"
    else
        git tag -a "v$version" -m "Release v$version"
        git push origin "v$version"
        success "Created and pushed tag v$version"
    fi
}

# ─── COMMANDS ───────────────────────────────────────────────────────────────
cmd_status() {
    echo ""
    echo -e "${CYAN}Plugin Status${NC}"
    echo "─────────────────────────────────"
    echo "Name:        $PLUGIN_NAME"
    echo "Version:     $(jq -r '.version' "$PLUGIN_JSON")"
    echo "Directory:   $PLUGIN_DIR"
    echo "Marketplace: $MARKETPLACE_NAME"
    echo ""

    # Check installed version
    local installed="$HOME/.claude/plugins/installed_plugins.json"
    local key="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
    if jq -e ".plugins[\"$key\"]" "$installed" >/dev/null 2>&1; then
        local inst_version=$(jq -r ".plugins[\"$key\"][0].version" "$installed")
        success "Installed: v$inst_version"
    else
        warn "Not installed"
    fi
}

cmd_release() {
    local bump_type="${1:-patch}"

    echo ""
    echo -e "${CYAN}═══ Releasing $PLUGIN_NAME ═══${NC}"
    echo ""

    validate
    local new_version=$(bump_version "$bump_type")
    git_commit "chore: release v$new_version"
    sync_marketplace
    git_push
    git_tag
    update_installed

    echo ""
    success "Released v$new_version"
    echo ""
    echo "Restart Claude Code to apply changes."
}

cmd_sync() {
    echo ""
    echo -e "${CYAN}═══ Syncing $PLUGIN_NAME ═══${NC}"
    echo ""

    validate
    sync_marketplace
    update_installed

    echo ""
    success "Sync complete"
}

cmd_help() {
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  status              Show plugin status"
    echo "  sync                Validate and sync to marketplace"
    echo "  release [type]      Bump version and release (type: patch|minor|major)"
    echo "  validate            Validate plugin structure"
    echo "  help                Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 status           # Check current status"
    echo "  $0 sync             # Sync without version bump"
    echo "  $0 release          # Release with patch bump"
    echo "  $0 release minor    # Release with minor bump"
}

# ─── MAIN ───────────────────────────────────────────────────────────────────
case "${1:-help}" in
    status)   cmd_status ;;
    sync)     cmd_sync ;;
    release)  cmd_release "${2:-patch}" ;;
    validate) validate ;;
    help|-h|--help) cmd_help ;;
    *)
        error "Unknown command: $1"
        cmd_help
        ;;
esac
