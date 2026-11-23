#!/usr/bin/env bash
# preToolUse hook (matcher: bash|powershell): refuse shell commands that destroy
# work git cannot give back. Copilot receives the reason and picks a safer route;
# everything else passes through untouched.
#
# A preToolUse hook that crashes denies the tool call, so this script must not
# fail on its own: without jq it lets the command through and says so.
set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "block-destructive hook: jq is not installed, guard is inactive" >&2
    exit 0
fi

# toolArgs arrives as an object; older versions sent it as a JSON-encoded string.
command=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.command // "") else "" end' 2>/dev/null)

deny() {
    jq -cn --arg reason "$1" '{permissionDecision: "deny", permissionDecisionReason: $reason}'
    exit 0
}

# Scratch directories may go: a single /tmp/<name> path, or "$var" when the same command filled
# var with mktemp. Those rm calls are replaced by `true` (a trailing ; marks the end), so any
# other recursive delete in the command is still checked below.
rm_flags='rm([[:space:]]+-[[:alpha:]]+)+[[:space:]]+'
rm_end='([[:space:]]*[;&|)'"'"'])'
rm_check=$(printf '%s;' "$command" | tr '\n' ';' \
    | sed -E "s#${rm_flags}\"?(/private)?/tmp/[[:alnum:]_-][[:alnum:]._-]*/?\"?${rm_end}#true\\3#g")
for var in $(printf '%s' "$command" | grep -oE '[[:alpha:]_][[:alnum:]_]*="?\$\(mktemp' | cut -d= -f1); do
    rm_check=$(printf '%s' "$rm_check" | sed -E "s#${rm_flags}\"?\\\$\\{?${var}\\}?\"?${rm_end}#true\\2#g")
done

# Wiping build output is routine; any other recursive force-delete is not.
# Flags are checked separately so `rm -rf`, `rm -fr` and `rm -r -f` all match.
if printf '%s' "$rm_check" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]' \
    && printf '%s' "$rm_check" | grep -Eq '[[:space:]](-[[:alpha:]]*[rR]|--recursive)' \
    && printf '%s' "$rm_check" | grep -Eq '[[:space:]](-[[:alpha:]]*f|--force)' \
    && ! printf '%s' "$command" | grep -Eq '^rm -rf (\./)?((engine/|api/)?build|web/dist)/?$'; then
    deny "block-destructive hook: recursive force-delete is blocked. Only build output (build, engine/build, api/build, web/dist) and scratch directories (/tmp/<name>, or a variable this same command set with mktemp) may be removed this way; delete specific files instead."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+reset[[:space:]].*--hard'; then
    deny "block-destructive hook: git reset --hard discards uncommitted work. Use git stash, or git reset --soft."
fi

# --force-with-lease is the safe variant, so only bare -f / --force is blocked.
if printf '%s' "$command" | grep -Eq 'git[[:space:]]+push([[:space:]].*)?[[:space:]](-f|--force)([[:space:]]|$)'; then
    deny "block-destructive hook: force-push is blocked. Use git push --force-with-lease, or ask the user."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[[:alpha:]]*f'; then
    deny "block-destructive hook: git clean -f deletes untracked files for good. Run git clean -n first and show the user the list."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+(checkout[[:space:]]+(--[[:space:]]+)?|restore[[:space:]]+)\.([[:space:]]|$)'; then
    deny "block-destructive hook: this discards every uncommitted change. Restore individual files, or git stash."
fi

exit 0
