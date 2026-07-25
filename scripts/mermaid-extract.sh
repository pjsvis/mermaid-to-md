#!/usr/bin/env bash
# mermaid-extract — extract ```mermaid blocks from markdown, render via mermaid-tui
# Usage: mermaid-extract.sh <file> [block-number]
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src/cli/mermaid-tui/target/release/mermaid-tui"
file="${1:?Usage: mermaid-extract.sh <file> [block-number]}"
block_filter="${2:-}"
[[ ! -f "$file" ]] && { echo "Error: not found: $file" >&2; exit 1; }
[[ ! -x "$BIN" ]] && { echo "Error: build first: cd src/cli/mermaid-tui && cargo build --release" >&2; exit 1; }

FENCE='```mermaid'
current=0; in_mermaid=false; buffer=""; capturing_key=false; key=""
is_list_item() { [[ "$1" =~ ^[0-9]+\.[[:space:]] ]]; }
is_blank()      { [[ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]]; }
emit_diagram() {
  local n="$1" buf="$2" k="$3"
  if [[ -z "$block_filter" || "$block_filter" == "$n" ]]; then
    echo "── Diagram $n ──"
    printf '%s' "$buf" | "$BIN" || true   # too-wide is a limitation, not an error
    echo ""
    if [[ -n "$k" ]]; then printf '%s' "$k"; echo ""; fi
  fi
  return 0
}
while IFS= read -r line; do
  if [[ "$line" == "$FENCE"* ]]; then
    # flush previous diagram if we were still capturing its key
    if $capturing_key; then emit_diagram "$current" "$buffer" "$key"; fi
    in_mermaid=true; buffer=""; current=$((current + 1)); key=""; capturing_key=false; continue
  fi
  if $in_mermaid && [[ "$line" == '```' ]]; then
    in_mermaid=false; capturing_key=true; continue
  fi
  $in_mermaid && buffer="${buffer}${line}"$'\n'
  if $capturing_key; then
    if is_list_item "$line"; then
      key="${key}${line}"$'\n'
    elif is_blank "$line" && [[ -z "$key" ]]; then
      : # blank line before the list — keep waiting
    elif is_blank "$line" && [[ -n "$key" ]]; then
      : # blank line within the list — tolerate
    else
      # non-list line: the key (if any) is complete
      emit_diagram "$current" "$buffer" "$key"
      capturing_key=false; key=""
    fi
  fi
done < "$file"
# flush if file ends while still capturing a key (or a no-key diagram)
if $capturing_key; then emit_diagram "$current" "$buffer" "$key"; fi
if (( $current == 0 )); then echo "No mermaid blocks found in $file" >&2; fi
