#!/usr/bin/env python3
"""Generates optimal hook configurations for discovered components."""
import json
import sys


def generate_mcp_hooks(servers: list) -> list:
    """Generate PreToolUse hooks for MCP servers."""
    hooks = []
    for server in servers:
        hooks.append({
            "matcher": f"mcp__{server['name']}__.*",
            "hooks": [{
                "type": "command",
                "command": f"echo \"[MCP] {server['name']} tool invoked at $(date)\" >> .claude/hooks/scripts/logs/mcp-usage.log"
            }]
        })
    return hooks


def generate_skill_validation_hooks(skills: list) -> list:
    """Generate validation hooks for skills that lack them."""
    hooks = []
    skills_without_hooks = [s for s in skills if not s.get("has_hooks", False)]

    if skills_without_hooks:
        hooks.append({
            "matcher": "Write|Edit",
            "hooks": [{
                "type": "command",
                "command": "echo \"[Skill] File modification detected at $(date)\" >> .claude/hooks/scripts/logs/skill-activity.log"
            }]
        })
    return hooks


def generate_agent_tracking_hooks(agents: list) -> list:
    """Generate hooks for tracking agent activity."""
    hooks = []
    if agents:
        hooks.append({
            "matcher": "Task",
            "hooks": [{
                "type": "command",
                "command": "echo \"[Agent] Subagent launched at $(date)\" >> .claude/hooks/scripts/logs/agent-activity.log"
            }]
        })
    return hooks


def generate_settings_config(inventory: dict) -> dict:
    """Generate complete settings.json hooks configuration."""
    mcp_servers = inventory.get("mcp_servers", [])
    skills = inventory.get("skills", [])
    agents = inventory.get("agents", [])

    config = {
        "hooks": {
            "PreToolUse": [],
            "PostToolUse": [],
            "SubagentStop": []
        }
    }

    # Add MCP hooks
    config["hooks"]["PreToolUse"].extend(generate_mcp_hooks(mcp_servers))

    # Add skill validation hooks
    config["hooks"]["PostToolUse"].extend(generate_skill_validation_hooks(skills))

    # Add agent tracking
    config["hooks"]["PreToolUse"].extend(generate_agent_tracking_hooks(agents))

    # Add SubagentStop logging
    config["hooks"]["SubagentStop"].append({
        "hooks": [{
            "type": "command",
            "command": "echo \"[Agent] Subagent completed at $(date)\" >> .claude/hooks/scripts/logs/agent-activity.log"
        }]
    })

    return config


def generate_remediation_commands(gaps: list) -> list:
    """Generate shell commands to fix identified gaps."""
    commands = []

    for gap in gaps:
        if gap["type"] == "script_not_executable":
            commands.append(f"chmod +x {gap['component']}")
        elif gap["type"] == "agent_no_skills":
            commands.append(f"# TODO: Add skills field to {gap['component']} agent")
        elif gap["type"] == "skill_no_hooks":
            commands.append(f"# TODO: Add hooks to {gap['component']} skill")

    return commands


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("Usage: python3 discover-ecosystem.py | python3 generate-integrations.py", file=sys.stderr)
        sys.exit(1)

    inventory = data.get("inventory", {})
    gaps = data.get("gaps", [])

    output = {
        "generated_hooks_config": generate_settings_config(inventory),
        "remediation_commands": generate_remediation_commands(gaps),
        "summary": {
            "mcp_hooks_generated": len(inventory.get("mcp_servers", [])),
            "gaps_with_remediations": len([g for g in gaps if g["type"] in ["script_not_executable", "agent_no_skills", "skill_no_hooks"]])
        }
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
