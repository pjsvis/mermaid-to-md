#!/usr/bin/env bash
# check-docs.sh — catch stale standard docs (about.md, README.md, USAGE.md).
#
# Standard docs rot when code ships without a doc update — "to be written"
# next to a shipped wrapper, "planned" next to a landed feature. This check
# greps for the stale-marker phrases and fails if any are older than the
# reality they describe.
#
# Allowlist: lines matching $ALLOW are legitimate pending items (currently:
# npm publishing, not yet on the registry). When the first npm release is
# published, remove its allowlist entry — any leftover placeholder language
# then fails the check. The allowlist rotting IS the signal to update the docs.
#
# CI-friendly: exits 0 if docs are current, 1 if any stale markers remain.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DOCS=(about.md README.md USAGE.md)
# Currently-legitimate pending: npm publishing (not yet on the registry).
# When the first npm release is published, drop this and fix any remaining hits.
ALLOW='once published|npm packaging is pending|npx mermaid-to-md'

STALE='to be written|to be implemented|not yet implemented|\(planned\)|planned, not yet'

stale=0
for f in "${DOCS[@]}"; do
  [[ -f "$f" ]] || continue
  # grep -n shows file:line; -E for the alternation; filter out allowlisted lines.
  hits="$(grep -nE "$STALE" "$f" | grep -vE "$ALLOW" || true)"
  if [[ -n "$hits" ]]; then
    while IFS= read -r line; do
      printf '%s:%s: stale doc marker\n' "$f" "$line" >&2
    done <<< "$hits"
    stale=1
  fi
done

if [[ "$stale" -ne 0 ]]; then
  echo "FAIL: standard docs have stale markers (code shipped, docs didn't follow)." >&2
  echo "      Fix the lines above, or update the allowlist in scripts/check-docs.sh" >&2
  echo "      if a marker is legitimately pending." >&2
  exit 1
fi
echo "ok — standard docs are current (no stale markers outside the allowlist)."
exit 0
