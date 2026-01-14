---
description: This skill should be used when the user asks to "add MCP server", "integrate MCP", "configure MCP in plugin", "use .mcp.json", "set up Model Context Protocol", "connect external service", mentions "${CLAUDE_PLUGIN_ROOT} with MCP", or discusses MCP server types (SSE, stdio, HTTP, WebSocket). Provides comprehensive guidance for integrating Model Context Protocol servers into Claude Code plugins for external tool and service integration.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
argument-hint: "<mcp-server-name> [server-type]"
---

# MCP Server Integration

Integrate Model Context Protocol servers into your Claude Code plugin.

**Request:** $ARGUMENTS

## MCP Configuration in Plugins

### Project-level (.mcp.json)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-name"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

### Plugin-bundled MCP Server

For plugins that include their own MCP server:

```json
{
  "mcpServers": {
    "my-plugin-server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/index.js"]
    }
  }
}
```

## Hook Integration with MCP

Create hooks that intercept MCP tool calls:

```yaml
# In settings.json
hooks:
  PreToolUse:
    - matcher: "mcp__server-name__.*"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/.claude/hooks/scripts/validate-mcp.sh"
```

## MCP Tool Discovery

```bash
# List all MCP servers
mcp-cli servers

# List tools from a server
mcp-cli tools server-name

# Get tool info
mcp-cli info server-name/tool-name

# Call an MCP tool
mcp-cli call server-name/tool-name '{"param": "value"}'
```

## Common MCP Patterns

### Database Integration
```json
{
  "mcpServers": {
    "postgresql": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgresql"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

### File System Access
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"]
    }
  }
}
```

### Web API Integration
```json
{
  "mcpServers": {
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
```

## Best Practices

1. **Environment Variables**: Use `${VAR}` syntax for secrets
2. **Minimal Permissions**: Only expose necessary endpoints
3. **Hook Validation**: Add PreToolUse hooks for sensitive operations
4. **Error Handling**: MCP servers should return clear error messages
5. **Documentation**: Document required environment variables
