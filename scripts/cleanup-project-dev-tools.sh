#!/usr/bin/env bash
#
# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  ⚠️  DO NOT RUN THIS SCRIPT UNTIL THE PLUGIN IS COMPLETE AND TESTED  ⚠️    ║
# ╠════════════════════════════════════════════════════════════════════════════╣
# ║  This script removes Claude Code development tools from a project after    ║
# ║  migrating to the claude-development plugin.                               ║
# ║                                                                            ║
# ║  Prerequisites:                                                            ║
# ║  1. Plugin is published and installable                                    ║
# ║  2. Plugin has been tested in target project                               ║
# ║  3. All development workflows work via plugin                              ║
# ║                                                                            ║
# ║  Run with --dry-run first to see what would be removed!                    ║
# ╚════════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./cleanup-project-dev-tools.sh /path/to/project --dry-run   # Preview changes
#   ./cleanup-project-dev-tools.sh /path/to/project             # Actually remove
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
PROJECT_DIR="${1:-}"
DRY_RUN=false

if [[ "$*" == *"--dry-run"* ]]; then
    DRY_RUN=true
fi

if [[ -z "$PROJECT_DIR" ]]; then
    echo -e "${RED}Error: Project directory required${NC}"
    echo "Usage: $0 /path/to/project [--dry-run]"
    exit 1
fi

if [[ ! -d "$PROJECT_DIR/.claude" ]]; then
    echo -e "${RED}Error: Not a Claude Code project (no .claude/ directory)${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude Code Development Tools Cleanup                         ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Project: ${PROJECT_DIR}${NC}"
if $DRY_RUN; then
    echo -e "${YELLOW}║  Mode: DRY RUN (no changes will be made)                      ║${NC}"
else
    echo -e "${RED}║  Mode: LIVE (files will be DELETED)                           ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# FILES AND DIRECTORIES TO REMOVE
# ============================================================================

# Development Skills (now in plugin)
DEV_SKILLS=(
    ".claude/skills/writing-skills"
    ".claude/skills/hook-development"
    ".claude/skills/create-hook-structure"
    ".claude/skills/ecosystem-analysis"
)

# Development Agents (now in plugin)
DEV_AGENTS=(
    ".claude/agents/skill-creator.md"
    ".claude/agents/agent-creator.md"
    ".claude/agents/hook-creator.md"
    ".claude/agents/skill-router.md"
    ".claude/agents/workflow-auditor.md"
)

# Validation Scripts (now in plugin)
DEV_SCRIPTS=(
    ".claude/hooks/scripts/agent-tools"
    ".claude/hooks/scripts/skill-tools"
    ".claude/hooks/scripts/hook-tools"
    ".claude/hooks/scripts/ecosystem"
    ".claude/hooks/scripts/scaffold-hooks.sh"
    ".claude/hooks/scripts/list-skills.sh"
)

# Documentation (now in plugin)
DEV_DOCS=(
    ".claude/claude-development.md"
)

# ============================================================================
# REMOVAL FUNCTIONS
# ============================================================================

remove_item() {
    local item="$1"
    local full_path="$PROJECT_DIR/$item"

    if [[ -e "$full_path" ]]; then
        if $DRY_RUN; then
            echo -e "  ${YELLOW}[DRY RUN]${NC} Would remove: $item"
        else
            rm -rf "$full_path"
            echo -e "  ${GREEN}[REMOVED]${NC} $item"
        fi
    else
        echo -e "  ${BLUE}[SKIP]${NC} Not found: $item"
    fi
}

# ============================================================================
# MAIN CLEANUP
# ============================================================================

echo -e "${BLUE}Removing Development Skills...${NC}"
for item in "${DEV_SKILLS[@]}"; do
    remove_item "$item"
done
echo ""

echo -e "${BLUE}Removing Development Agents...${NC}"
for item in "${DEV_AGENTS[@]}"; do
    remove_item "$item"
done
echo ""

echo -e "${BLUE}Removing Validation Scripts...${NC}"
for item in "${DEV_SCRIPTS[@]}"; do
    remove_item "$item"
done
echo ""

echo -e "${BLUE}Removing Development Documentation...${NC}"
for item in "${DEV_DOCS[@]}"; do
    remove_item "$item"
done
echo ""

# ============================================================================
# CLEANUP EMPTY DIRECTORIES
# ============================================================================

if ! $DRY_RUN; then
    echo -e "${BLUE}Cleaning up empty directories...${NC}"

    # Remove empty scripts directory if all subdirs were removed
    if [[ -d "$PROJECT_DIR/.claude/hooks/scripts" ]]; then
        if [[ -z "$(ls -A "$PROJECT_DIR/.claude/hooks/scripts" 2>/dev/null)" ]]; then
            rmdir "$PROJECT_DIR/.claude/hooks/scripts"
            echo -e "  ${GREEN}[REMOVED]${NC} .claude/hooks/scripts (empty)"
        fi
    fi

    # Remove empty hooks directory if scripts was the only thing
    if [[ -d "$PROJECT_DIR/.claude/hooks" ]]; then
        if [[ -z "$(ls -A "$PROJECT_DIR/.claude/hooks" 2>/dev/null)" ]]; then
            rmdir "$PROJECT_DIR/.claude/hooks"
            echo -e "  ${GREEN}[REMOVED]${NC} .claude/hooks (empty)"
        fi
    fi
    echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
if $DRY_RUN; then
    echo -e "${YELLOW}║  DRY RUN COMPLETE                                              ║${NC}"
    echo -e "${BLUE}║                                                                ║${NC}"
    echo -e "${BLUE}║  To actually remove files, run without --dry-run:             ║${NC}"
    echo -e "${BLUE}║  $0 $PROJECT_DIR${NC}"
else
    echo -e "${GREEN}║  CLEANUP COMPLETE                                              ║${NC}"
    echo -e "${BLUE}║                                                                ║${NC}"
    echo -e "${BLUE}║  Development tools removed. Using plugin instead.             ║${NC}"
    echo -e "${BLUE}║                                                                ║${NC}"
    echo -e "${BLUE}║  Next steps:                                                   ║${NC}"
    echo -e "${BLUE}║  1. Verify plugin is installed: claude plugins list            ║${NC}"
    echo -e "${BLUE}║  2. Test skill creation: Task skill-creator                   ║${NC}"
    echo -e "${BLUE}║  3. Commit the cleanup: git add -A && git commit              ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
