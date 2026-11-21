#!/usr/bin/env bash
# preToolUse hook (matcher: bash|powershell|view): keep .env files out of the
# conversation. A `--deny-tool='read(.env)'` rule only covers the file tools;
# `cat .env` in the shell still works, so the shell command is checked here too.
#
# This is a guard rail, not a security boundary: a determined command can hide
# the file name. Real isolation is the sandbox (guide 08).
set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "protect-secrets hook: jq is not installed, guard is inactive" >&2
    exit 0
fi

# What the tool is about to touch: a path for the file tools, a command for the shell.
target=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.path // .command // "") else "" end' 2>/dev/null)

# Matches .env and .env.local, but not .envrc or environment.ts.
if printf '%s' "$target" | grep -Eq '(^|[^[:alnum:]_])\.env(\.[[:alnum:]_-]+)?([^[:alnum:]_.-]|$)'; then
    jq -cn '{permissionDecision: "deny", permissionDecisionReason: "protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need."}'
fi

exit 0
