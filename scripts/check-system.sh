#!/usr/bin/env bash
# Checks the tools and versions the workshop needs. No login, no model call, no network.
# Run it the day before: bash scripts/check-system.sh (it also works outside the repository).
# On the day, scripts/check-setup.sh then checks your Copilot account and the repository.
set -u

failed=0
ok()   { printf '  ok    %-10s %s\n' "$1" "$2"; }
bad()  { printf '  FIX   %-10s %s\n        %s\n' "$1" "$2" "$3"; failed=$((failed + 1)); }
info() { printf '  --    %-10s %s\n' "$1" "$2"; }

# at_least 1.0.114 1.0.9 → true when the first version is the same or newer
at_least() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$2" ]; }

echo "System: $(uname -s) $(uname -m)$(grep -qi microsoft /proc/version 2>/dev/null && echo ' (WSL)')"

v=$(git --version 2>/dev/null | awk '{print $3}')
[ -n "$v" ] && ok git "$v" || bad git "missing" "Install git."

v=$(jq --version 2>/dev/null | sed 's/^jq-//')
[ -n "$v" ] && ok jq "$v" || bad jq "missing" "Install jq: the hooks need it (brew install jq, apt install jq)."

# macOS ships a /usr/bin/java stub that fails without a JDK, so ask java for its version.
v=$(java -version 2>&1 | awk -F'"' '/version/ {print $2; exit}')
major=${v%%.*}
if [ -z "$v" ]; then
    bad java "no JDK answers" "Install JDK 17-27. macOS: brew install --cask temurin, or brew install openjdk and add \$(brew --prefix openjdk)/bin to PATH."
elif [ "$major" -ge 17 ] && [ "$major" -le 27 ]; then ok java "$v"
else bad java "$v" "Use a JDK between 17 and 27; Gradle downloads JDK 21 for the build itself."; fi

v=$(node --version 2>/dev/null | sed 's/^v//')
major=${v%%.*}
if [ -z "$v" ]; then bad node "missing" "Install Node.js 24.15+ or 26."
elif { [ "$major" = 24 ] && at_least "$v" 24.15.0; } || [ "$major" = 26 ]; then ok node "$v"
else bad node "$v" "Use Node.js 24.15+ or 26."; fi

v=$(copilot --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -z "$v" ]; then bad copilot "missing" "npm install -g @github/copilot, then copilot login."
elif at_least "$v" 1.0.114; then ok copilot "$v"
else bad copilot "$v" "Update to 1.0.114 or newer: npm install -g @github/copilot."; fi

# An exported token overrides the stored login and may belong to an account without a seat.
tokens=$(env | grep -oE '^(COPILOT_GITHUB|GH|GITHUB)_TOKEN' | tr '\n' ' ')
[ -z "$tokens" ] && ok tokens "none exported" || bad tokens "$tokens" "Unset them, or make sure they belong to the account with the Copilot seat."

echo "Optional"
v=$(gh --version 2>/dev/null | awk 'NR==1 {print $3}');            [ -n "$v" ] && ok gh "$v" || info gh "not installed (exercise 4 files an issue with it)"
v=$(uv --version 2>/dev/null | awk '{print $2}');                  [ -n "$v" ] && ok uv "$v" || info uv "not installed (Conductor in guide 10)"
v=$(conductor --version 2>/dev/null | grep -oE '[0-9][0-9.]+' | head -1); [ -n "$v" ] && ok conductor "$v" || info conductor "not on PATH (guide 10; after uv tool install run uv tool update-shell)"

echo
if [ "$failed" -eq 0 ]; then echo "Ready. On the day: copilot login, clone, then scripts/check-setup.sh."
else echo "$failed item(s) to fix."; exit 1; fi
