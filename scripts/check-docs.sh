#!/usr/bin/env bash
# check-docs.sh — catch stale standard docs (about.md, README.md, USAGE.md).
#
# Standard docs rot when code ships without a doc update — "to be written"
# next to a shipped wrapper, "planned" next to a landed feature. This check
# greps for the stale-marker phrases and fails if any are older than the
# reality they describe.
#
# Allowlist: lines matching $ALLOW are legitimate pending items. There are
# none today: the install truth is S6 in docs/statements.md, and "unpublished"
# is a fact, not a placeholder. After the first release, update S6 and the
# install-status lines together.
#
# The claims ledger (docs/statements.md) is the single source of product
# statements. Standard docs must link it, the ledger must carry the expected
# statement IDs, and no doc may carry a rot-prone test count — the suite
# prints its own count.
#
# CI-friendly: exits 0 if docs are current, 1 if any stale markers remain.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DOCS=(about.md README.md USAGE.md docs/statements.md)
LINK_DOCS=(README.md about.md USAGE.md DEPENDENCIES.md)
INSTALL_DOCS=(README.md DEPENDENCIES.md)
STATEMENTS="docs/statements.md"
ALLOW='no-such-allowlisted-marker'

STALE='to be written|to be implemented|not yet implemented|\(planned\)|planned, not yet'
COUNTS='(^|[^0-9])[0-9]+ assertions|[0-9]+/[0-9]+ assertions'

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

# 1. Counts in prose rot. The suite is the only place a count belongs.
for f in "${DOCS[@]}"; do
  [[ -f "$f" ]] || continue
  hits="$(grep -nE "$COUNTS" "$f" || true)"
  if [[ -n "$hits" ]]; then
    while IFS= read -r line; do
      printf '%s:%s: test count in prose — run just test\n' "$f" "$line" >&2
    done <<< "$hits"
    stale=1
  fi
done

# 2. The ledger is the source; every standard doc points at it.
if [[ ! -f "$STATEMENTS" ]]; then
  printf '%s: missing product statements ledger\n' "$STATEMENTS" >&2
  stale=1
fi
for f in "${LINK_DOCS[@]}"; do
  if [[ -f "$f" ]] && ! grep -q 'docs/statements.md' "$f"; then
    printf '%s: missing link to %s\n' "$f" "$STATEMENTS" >&2
    stale=1
  fi
done

# 3. The expected IDs are present. A statement that loses its row is a claim
#    that silently stopped being governed.
for id in S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11; do
  if ! grep -q "^| ${id} |" "$STATEMENTS" 2>/dev/null; then
    printf '%s: missing statement %s\n' "$STATEMENTS" "$id" >&2
    stale=1
  fi
done

# 4. Install truth is named in both places a user may start from.
for f in "${INSTALL_DOCS[@]}"; do
  if [[ -f "$f" ]] && ! grep -q 'Install status (S6)' "$f"; then
    printf '%s: missing install status (S6)\n' "$f" >&2
    stale=1
  fi
done

if [[ "$stale" -ne 0 ]]; then
  echo "FAIL: standard docs have stale markers or broken statement links." >&2
  echo "      Fix the lines above; the claims ledger is docs/statements.md." >&2
  exit 1
fi
echo "ok — standard docs are current; statements and links resolve."
exit 0
