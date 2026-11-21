#!/usr/bin/env bash
# sessionStart hook: tell Copilot which branch it is on and which files are
# uncommitted, so it does not assume a clean tree. This is a snapshot taken
# when the session starts; it is not refreshed on later prompts.
set -euo pipefail

# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

command -v jq >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git branch --show-current 2>/dev/null)
branch=${branch:-"(detached HEAD)"}
changes=$(git status --porcelain 2>/dev/null)

if [ -z "$changes" ]; then
    context="Git: on branch $branch, working tree clean."
else
    count=$(printf '%s\n' "$changes" | wc -l | tr -d ' ')
    # Cap the list so a huge diff cannot flood the context window.
    files=$(printf '%s\n' "$changes" | head -10 | awk '{print $NF}' | paste -sd ',' - | sed 's/,/, /g')
    context="Git: on branch $branch, $count uncommitted file(s): $files"
    if [ "$count" -gt 10 ]; then
        context="$context, ..."
    fi
fi

# jq escapes quotes and backslashes in file names.
jq -cn --arg context "$context" '{additionalContext: $context}'
