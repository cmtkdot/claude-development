#!/usr/bin/env python3
"""
Error Recovery Patterns for Hooks

Patterns included:
1. Retry with exponential backoff
2. Circuit breaker
3. Graceful degradation

Use these patterns for hooks that call external services or have failure modes.
"""
import sys
import json
import time
import os
from pathlib import Path


# ═══════════════════════════════════════════════════════════════════════════════
# PATTERN 1: RETRY WITH EXPONENTIAL BACKOFF
# ═══════════════════════════════════════════════════════════════════════════════

def call_with_retry(func, *args, max_retries=3, **kwargs):
    """
    Call function with exponential backoff retry.

    Usage:
        result = call_with_retry(external_api.validate, data)

    Retries: 1s, 2s, 4s (exponential backoff)
    """
    for attempt in range(max_retries):
        try:
            return {'success': True, 'result': func(*args, **kwargs)}
        except Exception as e:
            if attempt == max_retries - 1:
                return {'success': False, 'error': str(e)}

            # Exponential backoff: 2^attempt seconds
            time.sleep(2 ** attempt)

    return {'success': False, 'error': 'Max retries exceeded'}


# ═══════════════════════════════════════════════════════════════════════════════
# PATTERN 2: CIRCUIT BREAKER
# ═══════════════════════════════════════════════════════════════════════════════

class CircuitBreaker:
    """
    Circuit breaker prevents cascading failures.

    States:
    - CLOSED: Normal operation, failures tracked
    - OPEN: Too many failures, requests bypassed for timeout period
    - HALF-OPEN: After timeout, allow one request to test recovery

    Usage:
        breaker = CircuitBreaker(failure_threshold=5, timeout=60)

        if breaker.is_open():
            # Skip external call, use fallback
            return fallback_result

        try:
            result = external_call()
            breaker.record_success()
        except Exception:
            breaker.record_failure()
    """

    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        project_dir = os.environ.get('CLAUDE_PROJECT_DIR', '.')
        self.state_file = Path(project_dir) / '.claude/hooks/.circuit-breaker-state.json'

    def get_state(self) -> dict:
        """Get current circuit breaker state."""
        if not self.state_file.exists():
            return {'failures': 0, 'opened_at': None, 'state': 'closed'}

        try:
            with open(self.state_file, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {'failures': 0, 'opened_at': None, 'state': 'closed'}

    def save_state(self, state: dict):
        """Save circuit breaker state."""
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.state_file, 'w') as f:
            json.dump(state, f)

    def record_failure(self):
        """Record a failure."""
        state = self.get_state()
        state['failures'] += 1

        if state['failures'] >= self.failure_threshold:
            state['opened_at'] = time.time()
            state['state'] = 'open'

        self.save_state(state)

    def record_success(self):
        """Record a success, reset circuit."""
        if self.state_file.exists():
            self.state_file.unlink()

    def is_open(self) -> bool:
        """Check if circuit is open (blocking requests)."""
        state = self.get_state()

        if state['state'] != 'open':
            return False

        # Check if timeout has passed (half-open state)
        if state['opened_at'] and time.time() - state['opened_at'] > self.timeout:
            # Allow one request through (half-open)
            state['state'] = 'half-open'
            self.save_state(state)
            return False

        return True


# ═══════════════════════════════════════════════════════════════════════════════
# PATTERN 3: GRACEFUL DEGRADATION
# ═══════════════════════════════════════════════════════════════════════════════

def validate_with_fallback(input_data: dict, breaker: CircuitBreaker) -> dict:
    """
    Validate with graceful degradation.

    Priority order:
    1. Full external validation (if available)
    2. Basic local validation (fallback)
    3. Allow with warning (last resort)
    """
    hook_event = input_data.get('hook_event_name', 'PreToolUse')

    # Check circuit breaker first
    if breaker.is_open():
        return {
            'decision': 'allow',
            'message': '⚠️  Circuit breaker open - using fallback',
            'hook_event': hook_event
        }

    # Try primary validation
    try:
        # Your external validation call here
        # result = external_validator.validate(input_data)
        result = {'valid': True}  # Placeholder

        breaker.record_success()

        return {
            'decision': 'allow' if result.get('valid') else 'deny',
            'message': '✅ Validated',
            'hook_event': hook_event
        }

    except Exception as e:
        breaker.record_failure()

        # Fall back to basic validation
        try:
            # Basic local checks
            command = input_data.get('tool_input', {}).get('command', '')
            if 'rm -rf /' in command:
                return {
                    'decision': 'deny',
                    'message': '🚫 Blocked (fallback validation)',
                    'hook_event': hook_event
                }

            return {
                'decision': 'allow',
                'message': f'⚠️  Fallback validation: {str(e)}',
                'hook_event': hook_event
            }

        except Exception:
            # Last resort: allow with warning
            return {
                'decision': 'allow',
                'message': '⚠️  Validation unavailable - allowing',
                'hook_event': hook_event
            }


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    input_data = json.load(sys.stdin)
    breaker = CircuitBreaker(failure_threshold=5, timeout=60)

    result = validate_with_fallback(input_data, breaker)

    output = {
        'systemMessage': result['message'],
        'hookSpecificOutput': {
            'hookEventName': result['hook_event'],
            'permissionDecision': result['decision']
        }
    }

    print(json.dumps(output))
    sys.exit(0 if result['decision'] == 'allow' else 2)


if __name__ == '__main__':
    main()
