#!/usr/bin/env bash
# agentStop hook: when Copilot finishes a turn, run the tests for the parts of
# the tree that have uncommitted changes and show a one-line result.
#
# Advisory by design: it never sends Copilot back to work, so a live workshop
# session cannot get stuck in a fix-the-tests loop. Exercise 3 turns it into a
# blocking gate.
set -uo pipefail

# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# agentStop fires after every turn, including plain questions. Only test what changed.
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
failed=""

if printf '%s\n' "$changed" | grep -Eq '^(engine|api)/'; then
    ./gradlew test --quiet >/dev/null 2>&1 || failed="$failed gradle"
fi

if printf '%s\n' "$changed" | grep -Eq '^web/src/' && [ -d web/node_modules ]; then
    (cd web && npm test --silent >/dev/null 2>&1) || failed="$failed web"
fi

if [ -n "$failed" ]; then
    # Exit code 2 shows stderr to the user as a warning without blocking the turn.
    echo "run-tests hook: tests are failing in:$failed" >&2
    exit 2
fi

exit 0
