#!/usr/bin/env bash
# Usage: instruction-audit.sh <repo-dir>...   Lists every instruction file Copilot CLI would load, per repo.
set -euo pipefail
for repo in "$@"; do
  ( cd "$repo" && copilot instruction list --json 2>/dev/null \
      | jq -r '.[] | [.location, .sourcePath, ((.applyTo // ["every session"]) | join(","))] | @tsv' \
      | while IFS=$'\t' read -r loc file scope; do
          printf '%s\t%s\t%s\t%s\t%s bytes\n' "$(basename "$repo")" "$loc" "$file" "$scope" "$(wc -c < "$file" | tr -d ' ')"
        done )
done
