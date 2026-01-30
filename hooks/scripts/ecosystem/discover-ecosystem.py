#!/usr/bin/env python3
"""Discovers all Claude Code components and outputs unified inventory."""
import json
import os
import re
from pathlib import Path


def parse_frontmatter(content: str) -> dict:
    """Parse YAML frontmatter from markdown content."""
    if not content.startswith("---"):
        return {}

    try:
        end = content.index("---", 3)
        frontmatter = content[3:end].strip()
        result = {}
        for line in frontmatter.split("\n"):
            if ":" in line:
                key, value = line.split(":", 1)
                result[key.strip()] = value.strip()
        return result
    except (ValueError, IndexError):
        return {}


def discover_skills() -> list:
    """Find all SKILL.md files in project and personal directories."""
    locations = [
        Path.home() / ".claude" / "skills",
        Path(".claude") / "skills"
    ]
    skills = []

    for loc in locations:
        if loc.exists():
            for skill_dir in loc.iterdir():
                if skill_dir.is_dir():
                    skill_file = skill_dir / "SKILL.md"
                    if skill_file.exists():
                        try:
                            content = skill_file.read_text()
                            frontmatter = parse_frontmatter(content)
                            has_hooks = "hooks:" in content.lower()
                            skills.append({
                                "name": skill_dir.name,
                                "path": str(skill_file),
                                "scope": "personal" if str(Path.home()) in str(loc) else "project",
                                "has_hooks": has_hooks,
                                "description": frontmatter.get("description", "")[:100]
                            })
                        except Exception:
                            skills.append({
                                "name": skill_dir.name,
                                "path": str(skill_file),
                                "scope": "personal" if str(Path.home()) in str(loc) else "project",
                                "has_hooks": False,
                                "description": ""
                            })
    return skills


def discover_agents() -> list:
    """Find all agent definitions."""
    locations = [
        Path.home() / ".claude" / "agents",
        Path(".claude") / "agents"
    ]
    agents = []

    for loc in locations:
        if loc.exists():
            for agent_file in loc.glob("*.md"):
                if agent_file.name == "CLAUDE.md":
                    continue
                try:
                    content = agent_file.read_text()
                    frontmatter = parse_frontmatter(content)
                    has_skills = "skills:" in content.lower() or "skills" in frontmatter
                    agents.append({
                        "name": agent_file.stem,
                        "path": str(agent_file),
                        "scope": "personal" if str(Path.home()) in str(loc) else "project",
                        "has_skills": has_skills,
                        "skills": frontmatter.get("skills", ""),
                        "model": frontmatter.get("model", "")
                    })
                except Exception:
                    agents.append({
                        "name": agent_file.stem,
                        "path": str(agent_file),
                        "scope": "personal" if str(Path.home()) in str(loc) else "project",
                        "has_skills": False,
                        "skills": "",
                        "model": ""
                    })
    return agents


def discover_mcp() -> list:
    """Find MCP server configurations."""
    mcp_files = [
        Path.home() / ".claude" / ".mcp.json",
        Path(".mcp.json")
    ]
    servers = []

    for mcp_file in mcp_files:
        if mcp_file.exists():
            try:
                with open(mcp_file) as f:
                    config = json.load(f)
                    for name, details in config.get("mcpServers", {}).items():
                        servers.append({
                            "name": name,
                            "tools_pattern": f"mcp__{name}__*",
                            "source": str(mcp_file),
                            "command": details.get("command", ""),
                            "scope": "personal" if str(Path.home()) in str(mcp_file) else "project"
                        })
            except json.JSONDecodeError:
                pass
    return servers


def discover_hooks() -> dict:
    """Find existing hook configurations."""
    settings_files = [
        Path.home() / ".claude" / "settings.json",
        Path(".claude") / "settings.json"
    ]
    hooks = {
        "PreToolUse": [],
        "PostToolUse": [],
        "Stop": [],
        "SubagentStop": [],
        "SubagentStart": [],
        "SessionStart": [],
        "SessionEnd": [],
        "UserPromptSubmit": []
    }

    for settings_file in settings_files:
        if settings_file.exists():
            try:
                with open(settings_file) as f:
                    config = json.load(f)
                    for event, handlers in config.get("hooks", {}).items():
                        if event in hooks:
                            for handler in handlers:
                                handler["source"] = str(settings_file)
                                hooks[event].append(handler)
            except json.JSONDecodeError:
                pass
    return hooks


def discover_hook_scripts() -> list:
    """Find all hook scripts in hooks/scripts directories."""
    locations = [
        Path.home() / ".claude" / "hooks" / "scripts",
        Path(".claude") / "hooks" / "scripts"
    ]
    scripts = []

    for loc in locations:
        if loc.exists():
            for script_file in loc.iterdir():
                if script_file.is_file() and script_file.name != "CLAUDE.md":
                    scripts.append({
                        "name": script_file.name,
                        "path": str(script_file),
                        "scope": "personal" if str(Path.home()) in str(loc) else "project",
                        "executable": os.access(script_file, os.X_OK)
                    })
    return scripts


def analyze_gaps(skills: list, agents: list, mcp_servers: list, hooks: dict, hook_scripts: list) -> list:
    """Find integration opportunities."""
    gaps = []

    # Skills without hooks
    for skill in skills:
        if not skill["has_hooks"]:
            gaps.append({
                "type": "skill_no_hooks",
                "component": skill["name"],
                "severity": "low",
                "recommendation": f"Add PreToolUse/PostToolUse hooks to {skill['name']} skill"
            })

    # Agents without skills
    for agent in agents:
        if not agent["has_skills"]:
            gaps.append({
                "type": "agent_no_skills",
                "component": agent["name"],
                "severity": "medium",
                "recommendation": f"Add skills field to {agent['name']} agent"
            })

    # MCP servers without hooks
    hooked_patterns = set()
    for handlers in hooks.values():
        for h in handlers:
            if "matcher" in h:
                hooked_patterns.add(h["matcher"])

    for server in mcp_servers:
        pattern = f"mcp__{server['name']}__"
        if not any(pattern in p for p in hooked_patterns):
            gaps.append({
                "type": "mcp_no_hooks",
                "component": server["name"],
                "severity": "low",
                "recommendation": f"Add PreToolUse hook for {server['tools_pattern']}"
            })

    # Non-executable hook scripts
    for script in hook_scripts:
        if not script["executable"]:
            gaps.append({
                "type": "script_not_executable",
                "component": script["name"],
                "severity": "high",
                "recommendation": f"chmod +x {script['path']}"
            })

    return gaps


def main():
    skills = discover_skills()
    agents = discover_agents()
    mcp_servers = discover_mcp()
    hooks = discover_hooks()
    hook_scripts = discover_hook_scripts()
    gaps = analyze_gaps(skills, agents, mcp_servers, hooks, hook_scripts)

    report = {
        "inventory": {
            "skills": skills,
            "agents": agents,
            "mcp_servers": mcp_servers,
            "hooks_by_event": {k: len(v) for k, v in hooks.items()},
            "hook_scripts": hook_scripts
        },
        "gaps": gaps,
        "summary": {
            "total_skills": len(skills),
            "total_agents": len(agents),
            "total_mcp_servers": len(mcp_servers),
            "total_hook_scripts": len(hook_scripts),
            "total_gaps": len(gaps),
            "high_severity_gaps": len([g for g in gaps if g["severity"] == "high"]),
            "skills_with_hooks": len([s for s in skills if s["has_hooks"]]),
            "agents_with_skills": len([a for a in agents if a["has_skills"]])
        }
    }

    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
