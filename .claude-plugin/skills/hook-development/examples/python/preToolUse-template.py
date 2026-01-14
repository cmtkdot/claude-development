#!/usr/bin/env python3
"""
PreToolUse Hook Template (Python)

Use Python for:
- Complex logic with multiple branches
- Structured data transforms
- Security analysis with pattern matching
- Scoring/ranking algorithms

Performance budget: < 100ms for PreToolUse
"""
import sys
import json


def should_block(input_data: dict) -> tuple[bool, str]:
    """
    Your validation logic here.

    Returns:
        (should_block: bool, reason: str)
    """
    tool_input = input_data.get('tool_input', {})
    command = tool_input.get('command', '')

    # Example: Block dangerous commands
    dangerous_patterns = ['rm -rf /', 'DROP TABLE', 'xp_cmdshell']
    for pattern in dangerous_patterns:
        if pattern in command:
            return True, f"Dangerous pattern detected: {pattern}"

    return False, ""


def main():
    try:
        input_data = json.load(sys.stdin)
        hook_event = input_data.get('hook_event_name', 'PreToolUse')
        tool_name = input_data.get('tool_name', '')

        # Fast-path exit for non-matching tools
        if tool_name != 'Bash':
            sys.exit(0)

        block, reason = should_block(input_data)

        if block:
            output = {
                'systemMessage': f'🚫 Blocked: {reason}',
                'hookSpecificOutput': {
                    'hookEventName': hook_event,
                    'permissionDecision': 'deny',
                    'permissionDecisionReason': reason
                }
            }
            print(json.dumps(output))
            sys.exit(2)

        # Success - allow with optional message
        output = {
            'systemMessage': '✅ Validated',
            'hookSpecificOutput': {
                'hookEventName': hook_event,
                'permissionDecision': 'allow'
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    except Exception as e:
        # Graceful degradation: allow on error with warning
        output = {'systemMessage': f'⚠️  Hook error: {str(e)}'}
        print(json.dumps(output))
        sys.exit(0)


if __name__ == '__main__':
    main()
