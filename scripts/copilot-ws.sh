#!/usr/bin/env bash
# Start Copilot CLI with the workshop's permission rules.
#
# Copilot CLI has no committed allow/deny file, so a repository shares its rules
# either through hooks (.github/hooks/) or through launch flags like these.
# Rules given here last for this run only; a deny rule beats every allow.
#
#   scripts/copilot-ws.sh                 # interactive session
#   scripts/copilot-ws.sh -p "..."        # any extra flags are passed through
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

exec copilot \
    --allow-tool='shell(./gradlew:*)' \
    --allow-tool='shell(npm test)' \
    --allow-tool='shell(npm run)' \
    --deny-tool='read(.env)' \
    --deny-tool='write(.env)' \
    "$@"
