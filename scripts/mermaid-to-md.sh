#!/usr/bin/env bash
# mermaid-to-md — render Mermaid source to markdown with baked Unicode art
# Usage:
#   mermaid-to-md.sh [<file.mmd>|-] [--title "T"] [-o <out.md>]   # bake
#   mermaid-to-md.sh --inject <file.md> [-o <out.md>]             # inject
#   mermaid-to-md.sh --verify <file.md>                          # verify (CI)
set -euo pipefail
BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/target/release/mermaid-tui"
mode="bake"; inject_file=""; title=""; outfile=""; infile=""
while (( $# )); do
  case "$1" in
    --inject)     mode="inject"; inject_file="${2:?--inject needs a file}"; shift 2;;
    --verify)     mode="verify"; verify_file="${2:?--verify needs a file}"; shift 2;;
    --title)      title="${2:?--title needs a value}";   shift 2;;
    -o|--output)  outfile="${2:?-o needs a value}";       shift 2;;
    -)            infile="-";                              shift;;
    -*)           echo "Usage: $0 [<file.mmd>|-] [--title T] [-o out] | --inject <file.md> [-o out] | --verify <file.md>" >&2; exit 2;;
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
    while IFS= read -r line || [[ -n "$line" ]]; do  # B2: keep a no-newline final line (td-774a89)
      line="${line%$'\r'}"   # tolerate CRLF line endings (td-b8d0d9)
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

# --- verify mode: re-render each ```mmd, diff against sentinel-marked art ---
# CI-friendly: no side effects. Exit 0 if all fresh, 1 if any stale/missing.
# Output to stderr: <file>:<line>: <status>  (stale | missing | unclosed-mmd | unclosed-text)
# Governs ```mmd blocks only; ```mermaid is GitHub's domain (run --inject to
# convert). ```text blocks without a sentinel are user content — not checked.
# A ```mmd with no following managed region is reported `missing` (run --inject).
if [[ "$mode" == "verify" ]]; then
  file="$verify_file"
  [[ -f "$file" ]] || { echo "Error: not found: $file" >&2; exit 1; }
  stale=0; line_no=0; mmd_line=0
  state=TEXT; buf=""; expected=""; actual=""
  while IFS= read -r line || [[ -n "$line" ]]; do  # B2: keep a no-newline final line (td-774a89)
    line="${line%$'\r'}"     # tolerate CRLF line endings (td-b8d0d9)
    line_no=$((line_no+1))
    case "$state" in
      TEXT)
        if [[ "$line" == '```mmd'* ]]; then state=IN_MMD; buf=""; mmd_line="$line_no"
        elif [[ "$line" == '```'* ]]; then state=IN_CODE; fi
        ;;
      IN_CODE)       # non-mmd code block (incl. unmarked ```text): skip verbatim
        [[ "$line" == '```' ]] && state=TEXT
        ;;
      IN_MMD)
        if [[ "$line" == '```' ]]; then
          expected="$(printf '%s' "$buf" | "$BIN" || true)"; state=AFTER_MMD
        else buf="${buf}${line}"$'\n'; fi
        ;;
      AFTER_MMD)     # skip blanks, expect the sentinel
        if [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then state=SKIP_SENTINEL
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
        elif [[ "$line" == '```mmd'* ]]; then
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1
          state=IN_MMD; buf=""; mmd_line="$line_no"
        elif [[ "$line" == '```'* ]]; then
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1; state=IN_CODE
        else
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1; state=TEXT
        fi
        ;;
      SKIP_SENTINEL) # expect ```text; else sentinel is orphaned -> missing
        if [[ "$line" == '```text' ]]; then state=SKIP_TEXT; actual=""
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
        elif [[ "$line" == '```mmd'* ]]; then
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1
          state=IN_MMD; buf=""; mmd_line="$line_no"
        elif [[ "$line" == '```'* ]]; then
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1; state=IN_CODE
        else
          printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1; state=TEXT
        fi
        ;;
      SKIP_TEXT)     # collect actual art until its closing fence, then diff
        if [[ "$line" == '```' ]]; then
          actual="${actual%$'\n'}"
          [[ "$actual" != "$expected" ]] && { printf '%s:%d: stale\n' "$file" "$mmd_line" >&2; stale=1; }
          state=TEXT
        else actual="${actual}${line}"$'\n'; fi
        ;;
    esac
  done < "$file"
  case "$state" in
    AFTER_MMD|SKIP_SENTINEL) printf '%s:%d: missing\n' "$file" "$mmd_line" >&2; stale=1;;
    IN_MMD)    printf '%s:%d: unclosed-mmd\n' "$file" "$mmd_line" >&2; stale=1;;
    SKIP_TEXT) printf '%s:%d: unclosed-text\n' "$file" "$mmd_line" >&2; stale=1;;
  esac
  [[ "$stale" -ne 0 ]] && exit 1
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
  # Source-first, with the sentinel — the same managed pair inject emits
  # (decisions/003). A baked file is a valid inject artifact: re-inject is
  # idempotent, --verify is fresh. No <details>: the source is a complexity
  # meter, left flat so it surfaces before the art tidies it away.
  printf '```mmd\n%s\n```\n\n' "$src"
  printf '<!-- mermaid-to-md:art -->\n```text\n%s\n```\n' "$art"
} > "${outfile:-/dev/stdout}"
