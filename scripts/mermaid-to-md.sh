#!/usr/bin/env bash
# mermaid-to-md — render Mermaid source to markdown with baked Unicode art
# Usage:
#   mermaid-to-md.sh [<file.mmd>|-] [--title "T"] [-o <out.md>]   # bake
#   mermaid-to-md.sh --inject <file.md> [-o <out.md>]             # inject
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/target/release/mermaid-tui"
mode="bake"; inject_file=""; title=""; outfile=""; infile=""
while (( $# )); do
  case "$1" in
    --inject)     mode="inject"; inject_file="${2:?--inject needs a file}"; shift 2;;
    --title)      title="${2:?--title needs a value}";   shift 2;;
    -o|--output)  outfile="${2:?-o needs a value}";       shift 2;;
    -)            infile="-";                              shift;;
    -*)           echo "Usage: $0 [<file.mmd>|-] [--title T] [-o out] | --inject <file.md> [-o out]" >&2; exit 2;;
    *)            infile="$1";                             shift;;
  esac
done
[[ ! -x "$BIN" ]] && { echo "Error: build first: cargo build --release" >&2; exit 1; }

# --- inject mode: render each ```mmd/```mermaid block, insert/replace art ---
# Sentinel <!-- mermaid-to-md:art --> marks tool-managed ```text blocks
# (see decisions/002-sentinel-convention.md). Idempotent: re-running replaces.
if [[ "$mode" == "inject" ]]; then
  file="$inject_file"
  [[ -f "$file" ]] || { echo "Error: not found: $file" >&2; exit 1; }
  tmp="$(mktemp)"
  state=TEXT; buf=""; blanks=""
  {
    while IFS= read -r line; do
      case "$state" in
        TEXT)
          if [[ "$line" == '```mmd'* || "$line" == '```mermaid'* ]]; then
            printf '```mmd\n'; state=IN_MMD; buf=""
          elif [[ "$line" == '```'* ]]; then
            printf '%s\n' "$line"; state=IN_CODE
          else
            printf '%s\n' "$line"
          fi
          ;;
        IN_CODE)       # non-mmd code block: emit verbatim, don't parse fences
          if [[ "$line" == '```' ]]; then printf '%s\n' "$line"; state=TEXT
          else printf '%s\n' "$line"; fi
          ;;
        IN_MMD)
          if [[ "$line" == '```' ]]; then
            printf '```\n'
            art="$(printf '%s' "$buf" | "$BIN" || true)"
            printf '\n<!-- mermaid-to-md:art -->\n```text\n%s\n```\n' "$art"
            state=AFTER_MMD; blanks=""
          else
            printf '%s\n' "$line"; buf="${buf}${line}"$'\n'
          fi
          ;;
        AFTER_MMD)     # fresh art emitted; consume any old sentinel+text block
          if [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
            state=SKIP_SENTINEL
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            blanks="${blanks}${line}"$'\n'
          elif [[ "$line" == '```mmd'* || "$line" == '```mermaid'* ]]; then
            printf '%s' "$blanks"; printf '```mmd\n'; state=IN_MMD; buf=""
          elif [[ "$line" == '```'* ]]; then
            printf '%s' "$blanks"; printf '%s\n' "$line"; state=IN_CODE
          else
            printf '%s' "$blanks"; printf '%s\n' "$line"; state=TEXT
          fi
          ;;
        SKIP_SENTINEL) # sentinel consumed; expect the ```text block it marks
          if [[ "$line" == '```text' ]]; then state=SKIP_TEXT
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
          else printf '%s\n' "$line"; state=TEXT; fi
          ;;
        SKIP_TEXT)     # discard old art content until its closing fence
          if [[ "$line" == '```' ]]; then state=TEXT; fi
          ;;
      esac
    done < "$file"
    if [[ "$state" == AFTER_MMD && -n "$blanks" ]]; then printf '%s' "$blanks"; fi
  } > "$tmp"
  if [[ -n "$outfile" ]]; then mv "$tmp" "$outfile"; else mv "$tmp" "$file"; fi
  exit 0
fi

# --- bake mode: render a .mmd source file (or stdin) to a standalone .md ---
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
