#!/usr/bin/env bash
# mermaid-to-md — render Mermaid source to markdown with baked Unicode art
# Usage: mermaid-to-md.sh [<file.mmd>|-] [--title "T"] [-o <out.md>]
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/target/release/mermaid-tui"
title=""; outfile=""; infile=""
while (( $# )); do
  case "$1" in
    --title)      title="${2:?--title needs a value}";   shift 2;;
    -o|--output)  outfile="${2:?-o needs a value}";       shift 2;;
    -)            infile="-";                              shift;;
    -*)           echo "Usage: $0 [<file.mmd>|-] [--title T] [-o out.md]" >&2; exit 2;;
    *)            infile="$1";                             shift;;
  esac
done
[[ ! -x "$BIN" ]] && { echo "Error: build first: cargo build --release" >&2; exit 1; }
if [[ -z "$infile" || "$infile" == "-" ]]; then src="$(cat)"; fname=""
else [[ -f "$infile" ]] || { echo "Error: not found: $infile" >&2; exit 1; }
  src="$(cat "$infile")"; fname="$(basename "${infile%.mmd}")"; fi
[[ -z "$title" && -n "$fname" ]] && { t="${fname//-/ }"; title="${t//_/ }"; }
# blank input → valid (near-)empty markdown, no crash
if [[ -z "$(printf '%s' "$src" | tr -d '[:space:]')" ]]; then
  if [[ -n "$title" ]]; then printf '# %s\n' "$title" > "${outfile:-/dev/stdout}"; fi
  exit 0
fi
art="$(printf '%s' "$src" | "$BIN" || true)"
{
  [[ -n "$title" ]] && printf '# %s\n\n' "$title"
  printf '```text\n%s\n```\n\n' "$art"
  printf '<details>\n<summary>Mermaid source</summary>\n\n```mmd\n%s\n```\n\n</details>\n' "$src"
} > "${outfile:-/dev/stdout}"
