#!/usr/bin/env bash
# postToolUse hook (matcher: edit|create|str_replace_editor|apply_patch): run
# Prettier on web source files Copilot just changed, and tell the model, because
# its picture of the file is stale once the formatter has rewritten it.
#
# Kotlin is left alone on purpose: formatting it means a Gradle task, which is
# too slow to run after every edit.
set -uo pipefail

input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
[ -x web/node_modules/.bin/prettier ] || exit 0

# The file tools pass an object with a `path`. apply_patch (used by some models
# instead of edit/create) passes the raw patch text, so the paths are read from
# its "*** Add File:" / "*** Update File:" headers.
paths=$(printf '%s' "$input" | jq -r '
    .toolArgs
    | if type == "object" then (.path // empty)
      elif type == "string" then (split("\n")[] | capture("^\\*\\*\\* (Add|Update) File: (?<path>.+)$")? | .path)
      else empty end' 2>/dev/null)

formatted=""
while IFS= read -r path; do
    [ -n "$path" ] || continue
    # Paths arrive absolute or relative depending on the tool; compare from the repo root.
    relative=${path#"$PWD"/}
    case "$relative" in
        web/src/*.ts | web/src/*.tsx | web/src/*.css)
            if [ -f "$relative" ] && web/node_modules/.bin/prettier --write "$relative" >/dev/null 2>&1; then
                formatted="$formatted ${relative##*/}"
            fi
            ;;
    esac
done <<EOF
$paths
EOF

if [ -n "$formatted" ]; then
    jq -cn --arg files "$formatted" \
        '{additionalContext: ("format hook: Prettier reformatted" + $files + ". Re-read the file before editing it again.")}'
fi

exit 0
