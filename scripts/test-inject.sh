#!/usr/bin/env bash
# test-inject.sh — persistent regression suite for mermaid-to-md inject/verify.
#
# Covers the Phase 2 (inject) and Phase 3 (verify) contract defined in
# briefs/001-mermaid-to-md.md and decisions/002-sentinel-convention.md.
#
# CI-friendly: self-contained (no bats/external deps), TAP-style output,
# exits 0 iff every assertion passes. Wire into CI: `scripts/test-inject.sh`.
#
# The 18 assertions below are the starting set derived from the spec; the
# ad-hoc session commands that verified Phase 2 (td-fba03a) are reproduced
# here so a fresh checkout can re-prove the "14 tests pass" claim.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/target/release/mermaid-tui"
SCRIPT="$ROOT/scripts/mermaid-to-md.sh"

if [[ ! -x "$BIN" ]]; then
  echo "Bail out! build first: cargo build --release (or: just build)" >&2
  exit 1
fi
if [[ ! -x "$SCRIPT" ]]; then
  echo "Bail out! wrapper not found: $SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── helpers ──────────────────────────────────────────────────────────────
NT=0; PASS=0; FAIL=0
LAST_OUT=""; LAST_ERR=""; LAST_RC=0

ok()    { NT=$((NT+1)); PASS=$((PASS+1)); printf 'ok %d - %s\n' "$NT" "$1"; }
notok() { NT=$((NT+1)); FAIL=$((FAIL+1)); printf 'not ok %d - %s\n' "$NT" "$1"
          [[ -n "${2:-}" ]] && printf '  %s\n' "$2" >&2; }

# run_sut <args...>  → sets LAST_OUT / LAST_ERR / LAST_RC
run_sut() {
  local err; err="$(mktemp)"
  LAST_OUT="$("$SCRIPT" "$@" 2>"$err")"; LAST_RC=$?
  LAST_ERR="$(cat "$err")"; rm -f "$err"
}

assert_eq()          { local n="$1" e="$2" a="$3"
                       if [[ "$e" == "$a" ]]; then ok "$n"
                       else notok "$n" "expected: <$e>; actual: <$a>"; fi; }
assert_contains()    { local n="$1" h="$2" needle="$3"
                       if [[ "$h" == *"$needle"* ]]; then ok "$n"
                       else notok "$n" "expected to contain: <$needle>"; fi; }
assert_not_contains(){ local n="$1" h="$2" needle="$3"
                       if [[ "$h" != *"$needle"* ]]; then ok "$n"
                       else notok "$n" "expected NOT to contain: <$needle>"; fi; }
assert_exit()        { local n="$1" exp="$2" rc="$3"
                       if [[ "$exp" == "$rc" ]]; then ok "$n"
                       else notok "$n" "expected exit $exp; actual: $rc"; fi; }
# grep -c always prints the count (even 0); || true only normalises exit status.
count_lines()        { grep -c -- "$1" "$2" 2>/dev/null || true; }

# ── fixtures ─────────────────────────────────────────────────────────────
# A single-edge graph; its rendered art contains "│ A │" and "│ B │".
MMD_SIMPLE='```mmd
graph TD
  A --> B
```'

printf 'TAP version 13\n'
printf '# mermaid-to-md inject/verify regression suite\n'

# =========================================================================
# Inject mode (12)
# =========================================================================

# 1. inject-fresh: --inject inserts a sentinel + ```text art block after mmd.
f="$TMP/fresh.md"; printf '%s\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"
assert_exit     "inject-fresh exits 0"            0 "$LAST_RC"
assert_contains "inject-fresh inserts sentinel"   "$(cat "$f")" '<!-- mermaid-to-md:art -->'
assert_contains "inject-fresh inserts text fence" "$(cat "$f")" '```text'

# 2. inject-fresh: the art block actually carries rendered output.
assert_contains "inject-fresh art has node A box" "$(cat "$f")" '│ A │'
assert_contains "inject-fresh art has node B box" "$(cat "$f")" '│ B │'

# 3. inject-fresh: the mmd source block is preserved verbatim.
assert_contains "inject-fresh source preserved (graph TD)" "$(cat "$f")" 'graph TD'
assert_contains "inject-fresh source preserved (edge)"     "$(cat "$f")" 'A --> B'

# 4. idempotency: re-running inject 3x yields exactly one sentinel + one art block.
f="$TMP/idem.md"; printf '%s\n' "$MMD_SIMPLE" > "$f"
for _ in 1 2 3; do run_sut --inject "$f"; done
assert_eq "idempotent-3x single sentinel"  1 "$(count_lines 'mermaid-to-md:art' "$f")"
assert_eq "idempotent-3x single text fence" 1 "$(count_lines '```text' "$f")"
assert_eq "idempotent-3x single mmd fence"  1 "$(count_lines '```mmd' "$f")"

# 5. idempotency post mermaid→mmd conversion: convert then re-inject stays stable.
f="$TMP/idem-conv.md"; printf '```mermaid\ngraph TD\n  A --> B\n```\n' > "$f"
run_sut --inject "$f"; run_sut --inject "$f"; run_sut --inject "$f"
assert_eq "idempotent-post-conversion single sentinel" 1 "$(count_lines 'mermaid-to-md:art' "$f")"
assert_eq "idempotent-post-conversion zero mermaid"    0 "$(count_lines '```mermaid' "$f")"

# 6. mermaid→mmd: a ```mermaid fence is converted to ```mmd on inject.
f="$TMP/conv.md"; printf '```mermaid\ngraph TD\n  A --> B\n```\n' > "$f"
run_sut --inject "$f"
assert_eq "mermaid-to-mmd leaves zero mermaid fences" 0 "$(count_lines '```mermaid' "$f")"
assert_eq "mermaid-to-mmd yields one mmd fence"       1 "$(count_lines '```mmd' "$f")"

# 7. non-mmd code blocks are emitted verbatim (not parsed as mermaid).
f="$TMP/code.md"
printf '```mmd\ngraph TD\n  A --> B\n```\n\n```sh\necho hello\n```\n' > "$f"
run_sut --inject "$f"
assert_contains "code-block preserved (sh fence)"  "$(cat "$f")" '```sh'
assert_contains "code-block preserved (sh content)" "$(cat "$f")" 'echo hello'

# 8. multi-diagram: each mmd block gets its own sentinel + art.
f="$TMP/multi.md"
printf '```mmd\ngraph TD\n  A --> B\n```\nmid\n```mmd\ngraph TD\n  C --> D\n```\n' > "$f"
run_sut --inject "$f"
assert_eq "multi-diagram two sentinels" 2 "$(count_lines 'mermaid-to-md:art' "$f")"

# 9. passthrough: plain text outside any block is unchanged.
f="$TMP/pass.md"
printf 'Intro line.\n\n%s\n\nOutro line.\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"
assert_contains "passthrough preserves intro"  "$(cat "$f")" 'Intro line.'
assert_contains "passthrough preserves outro"  "$(cat "$f")" 'Outro line.'

# 10. unmarked ```text blocks (no sentinel) are never touched by inject.
f="$TMP/unmarked.md"
printf '%s\n\n```text\nUSER ART\n```\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"
assert_contains "unmarked-text preserved" "$(cat "$f")" 'USER ART'
# exactly one sentinel (for the mmd), not two.
assert_eq "unmarked-text adds no extra sentinel" 1 "$(count_lines 'mermaid-to-md:art' "$f")"

# 11. -o writes to the target file and leaves the source byte-identical.
src="$TMP/src.md"; out="$TMP/out.md"; printf '%s\n' "$MMD_SIMPLE" > "$src"
cp "$src" "$TMP/src.before"
run_sut --inject "$src" -o "$out"
assert_exit "inject -o exits 0" 0 "$LAST_RC"
assert_eq "inject -o source untouched" "$(cat "$TMP/src.before")" "$(cat "$src")"
assert_contains "inject -o out has art" "$(cat "$out")" 'mermaid-to-md:art'

# 12. missing file → nonzero exit + error on stderr.
run_sut --inject "$TMP/does-not-exist.md"
assert_exit "inject-missing-file nonzero exit" 1 "$LAST_RC"
assert_contains "inject-missing-file stderr message" "$LAST_ERR" 'not found'

# =========================================================================
# Verify mode (6)
# =========================================================================

# 13. verify-fresh: a freshly injected file verifies clean (exit 0).
f="$TMP/vfresh.md"; printf '%s\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"
run_sut --verify "$f"
assert_exit "verify-fresh exits 0" 0 "$LAST_RC"

# 14. verify-stale: mmd source changed but art not regenerated → exit 1 + stale.
f="$TMP/vstale.md"
printf '```mmd\ngraph TD\n  A --> B --> C\n```\n<!-- mermaid-to-md:art -->\n```text\nOLD ART\n```\n' > "$f"
run_sut --verify "$f"
assert_exit "verify-stale exits 1" 1 "$LAST_RC"
assert_contains "verify-stale reports stale" "$LAST_ERR" 'stale'

# 15. verify-missing: mmd with no following managed region → exit 1 + missing.
f="$TMP/vmiss.md"
printf '```mmd\ngraph TD\n  A --> B\n```\nplain text, no art\n' > "$f"
run_sut --verify "$f"
assert_exit "verify-missing exits 1" 1 "$LAST_RC"
assert_contains "verify-missing reports missing" "$LAST_ERR" 'missing'

# 16. verify ignores unmarked ```text blocks (no false positive).
f="$TMP/vunmarked.md"; printf '%s\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"                       # fresh managed art
printf '\n```text\nUSER ART\n```\n' >> "$f" # unmarked user block appended
run_sut --verify "$f"
assert_exit "verify-ignores-unmarked exits 0" 0 "$LAST_RC"

# 17. verify is CI-friendly: no side effects (file byte-identical after verify).
f="$TMP/vsideeff.md"; printf '%s\n' "$MMD_SIMPLE" > "$f"
run_sut --inject "$f"; cp "$f" "$TMP/vsideeff.before"
run_sut --verify "$f"
assert_eq "verify-no-side-effects file unchanged" "$(cat "$TMP/vsideeff.before")" "$(cat "$f")"

# 18. verify missing file → nonzero exit.
run_sut --verify "$TMP/does-not-exist.md"
assert_exit "verify-missing-file nonzero exit" 1 "$LAST_RC"

# =========================================================================
# CRLF line endings (td-b8d0d9): Windows-authored files must not silently
# fail. Before the fix, a trailing \r on the closing fence breaks the exact
# match `[[ "$line" == '```' ]]` — inject drops all art (exit 0, no warning)
# and verify misreports `unclosed-mmd`. Fix: strip trailing \r after read.
# =========================================================================

# 19. inject-crlf: a CRLF markdown file gets art injected (not silently dropped).
f="$TMP/crlf-inj.md"
printf '```mmd\r\ngraph TD\r\n  A --> B\r\n```\r\n' > "$f"
run_sut --inject "$f"
assert_exit     "inject-crlf exits 0"          0 "$LAST_RC"
assert_contains "inject-crlf inserts sentinel" "$(cat "$f")" '<!-- mermaid-to-md:art -->'
assert_contains "inject-crlf art has node B"   "$(cat "$f")" '│ B │'

# 20. inject-crlf idempotent: re-running on the injected file doesn't duplicate.
run_sut --inject "$f"
assert_eq "inject-crlf idempotent single sentinel" 1 "$(count_lines 'mermaid-to-md:art' "$f")"

# 21. verify-crlf: a CRLF mmd block with no art reports `missing`, not `unclosed-mmd`.
f="$TMP/crlf-ver.md"
printf '```mmd\r\ngraph TD\r\n  A --> B\r\n```\r\nplain\r\n' > "$f"
run_sut --verify "$f"
assert_exit         "verify-crlf-missing exits 1"     1 "$LAST_RC"
assert_contains     "verify-crlf reports missing"     "$LAST_ERR" 'missing'
assert_not_contains "verify-crlf not unclosed-mmd"    "$LAST_ERR" 'unclosed'

# =========================================================================
# Bake mode (B1, brief 007 / decisions/003): bake and inject share one output
# shape — a baked file is a valid inject artifact with a sentinel+art region
# after each mmd. Before the unify, bake wrapped mmd in <details> with no
# following region, so --verify reported `missing` at every baked diagram.
# =========================================================================

# 22. bake: renders a .mmd source to a markdown file with sentinel + art, source-first.
src="$TMP/bake.mmd"; printf 'graph TD\n  A --> B\n' > "$src"
run_sut "$src" -o "$TMP/baked.md"
assert_exit     "bake exits 0"                 0 "$LAST_RC"
assert_contains "bake emits sentinel"          "$(cat "$TMP/baked.md")" '<!-- mermaid-to-md:art -->'
assert_contains "bake source-first (mmd fence)" "$(cat "$TMP/baked.md")" '```mmd'
assert_contains "bake art has node B"          "$(cat "$TMP/baked.md")" '│ B │'
assert_not_contains "bake has no details wrapper" "$(cat "$TMP/baked.md")" '<details>'

# 23. bake-then-verify: a freshly baked file verifies clean (B1 resolved).
run_sut --verify "$TMP/baked.md"
assert_exit "bake-then-verify exits 0" 0 "$LAST_RC"

# 24. bake-then-inject: re-injecting a baked file is idempotent (no dup art).
run_sut --inject "$TMP/baked.md"
assert_eq "bake-then-inject single sentinel"  1 "$(count_lines 'mermaid-to-md:art' "$TMP/baked.md")"
assert_eq "bake-then-inject single text fence" 1 "$(count_lines '```text' "$TMP/baked.md")"

# =========================================================================
printf '\n# %d/%d assertions pass (%d fail)\n' "$PASS" "$NT" "$FAIL"
[[ "$FAIL" -eq 0 ]]
