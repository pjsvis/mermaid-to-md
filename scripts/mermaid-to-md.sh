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
# Art-first managed region (decisions/004): sentinel → ```text art → ```mmd
# source. The sentinel OPENS the region; a bare ```mmd with no preceding
# sentinel is a fresh diagram. Idempotent: re-running re-renders in place.
# The sentinel convention itself is decisions/002; this is the post-004 order.
if [[ "$mode" == "inject" ]]; then
  file="$inject_file"
  [[ -f "$file" ]] || { echo "Error: not found: $file" >&2; exit 1; }
  tmp="$(mktemp)"
  state=TEXT; buf=""; blanks=""; via_sentinel=0
  {
    while IFS= read -r line || [[ -n "$line" ]]; do  # B2: keep a no-newline final line (td-774a89)
      line="${line%$'\r'}"   # tolerate CRLF line endings (td-b8d0d9)
      case "$state" in
        TEXT)
          # Sentinel opens the managed region (004). A bare ```mmd here is a
          # fresh diagram; a sentinel starts re-render of an existing region.
          if [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
            state=AT_SENTINEL
          elif [[ "$line" == '```mmd'* || "$line" == '```mermaid'* ]]; then
            state=IN_MMD; buf=""; via_sentinel=0
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
        AT_SENTINEL)   # sentinel consumed; expect the ```text art block to skip
          if [[ "$line" == '```text' ]]; then state=SKIP_ART
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
          else printf '%s\n' "$line"; state=TEXT; fi
          ;;
        SKIP_ART)      # discard existing art until its closing fence
          [[ "$line" == '```' ]] && state=LOOK_FOR_SRC
          ;;
        LOOK_FOR_SRC)  # old art dropped; expect the ```mmd source to re-render
          if [[ "$line" == '```mmd'* || "$line" == '```mermaid'* ]]; then
            state=IN_MMD; buf=""; via_sentinel=1
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
          elif [[ "$line" == '```'* ]]; then printf '%s\n' "$line"; state=IN_CODE
          else printf '%s\n' "$line"; state=TEXT; fi
          ;;
        IN_MMD)        # collect source; on close, emit the art-first region
          if [[ "$line" == '```' ]]; then
            art="$(printf '%s' "$buf" | "$BIN" || true)"
            printf '<!-- mermaid-to-md:art -->\n```text\n%s\n```\n\n```mmd\n%s```\n' "$art" "$buf"
            if [[ "$via_sentinel" == 1 ]]; then state=TEXT
            else state=AFTER_MMD; blanks=""; fi
          else
            buf="${buf}${line}"$'\n'
          fi
          ;;
        AFTER_MMD)     # bare-mmd region emitted; consume any trailing OLD
                       # (source-first) sentinel+text block so an old-format
                       # file converts cleanly on first re-inject.
          if [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
            state=SKIP_SENTINEL
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            blanks="${blanks}${line}"$'\n'
          elif [[ "$line" == '```mmd'* || "$line" == '```mermaid'* ]]; then
            printf '%s' "$blanks"; state=IN_MMD; buf=""; via_sentinel=0
          elif [[ "$line" == '```'* ]]; then
            printf '%s' "$blanks"; printf '%s\n' "$line"; state=IN_CODE
          else
            printf '%s' "$blanks"; printf '%s\n' "$line"; state=TEXT
          fi
          ;;
        SKIP_SENTINEL) # old sentinel consumed; expect its ```text block
          if [[ "$line" == '```text' ]]; then state=SKIP_TEXT
          elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
          else printf '%s\n' "$line"; state=TEXT; fi
          ;;
        SKIP_TEXT)     # discard old art content until its closing fence
          [[ "$line" == '```' ]] && state=TEXT
          ;;
      esac
    done < "$file"
    if [[ "$state" == AFTER_MMD && -n "$blanks" ]]; then printf '%s' "$blanks"; fi
  } > "$tmp"
  if [[ -n "$outfile" ]]; then mv "$tmp" "$outfile"; else mv "$tmp" "$file"; fi
  exit 0
fi

# --- verify mode: sentinel-anchored freshness check (decisions/004) ---
# CI-friendly: no side effects. Exit 0 if all fresh, 1 if any stale/missing.
# Output to stderr: <file>:<line>: <status>  (stale | missing | unclosed-mmd | unclosed-text)
# The sentinel opens the managed region: sentinel → ```text art → ```mmd
# source. A bare ```mmd with no preceding sentinel is `missing` (run --inject).
# ```text blocks without a sentinel are user content — not checked.
if [[ "$mode" == "verify" ]]; then
  file="$verify_file"
  [[ -f "$file" ]] || { echo "Error: not found: $file" >&2; exit 1; }
  stale=0; line_no=0; sentinel_line=0
  state=TEXT; actual=""; buf=""; expected=""
  while IFS= read -r line || [[ -n "$line" ]]; do  # B2: keep a no-newline final line (td-774a89)
    line="${line%$'\r'}"     # tolerate CRLF line endings (td-b8d0d9)
    line_no=$((line_no+1))
    case "$state" in
      TEXT)
        if [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
          state=IN_MANAGED; sentinel_line="$line_no"
        elif [[ "$line" == '```mmd'* ]]; then
          printf '%s:%d: missing\n' "$file" "$line_no" >&2; stale=1
          state=SKIP_TO_CLOSE
        elif [[ "$line" == '```'* ]]; then state=IN_CODE; fi
        ;;
      IN_CODE)       # non-mmd code block (incl. unmarked ```text): skip verbatim
        [[ "$line" == '```' ]] && state=TEXT
        ;;
      SKIP_TO_CLOSE) # consume an orphan mmd block (already reported missing)
        [[ "$line" == '```' ]] && state=TEXT
        ;;
      IN_MANAGED)    # after sentinel; expect ```text
        if [[ "$line" == '```text' ]]; then state=IN_ART; actual=""
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
        elif [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; sentinel_line="$line_no"
        elif [[ "$line" == '```mmd'* ]]; then
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; state=SKIP_TO_CLOSE
        elif [[ "$line" == '```'* ]]; then
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; state=IN_CODE
        else
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; state=TEXT
        fi
        ;;
      IN_ART)        # collect actual art until its closing fence
        if [[ "$line" == '```' ]]; then state=IN_MANAGED_SRC
        else actual="${actual}${line}"$'\n'; fi
        ;;
      IN_MANAGED_SRC) # after art close; expect ```mmd source
        if [[ "$line" == '```mmd'* ]]; then state=IN_SRC; buf=""
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then :
        elif [[ "$line" == '<!-- mermaid-to-md:art -->' ]]; then
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1
          state=IN_MANAGED; sentinel_line="$line_no"
        elif [[ "$line" == '```'* ]]; then
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; state=IN_CODE
        else
          printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1; state=TEXT
        fi
        ;;
      IN_SRC)        # collect source until close; render expected, diff
        if [[ "$line" == '```' ]]; then
          expected="$(printf '%s' "$buf" | "$BIN" || true)"
          actual="${actual%$'\n'}"
          [[ "$actual" != "$expected" ]] && { printf '%s:%d: stale\n' "$file" "$sentinel_line" >&2; stale=1; }
          state=TEXT
        else buf="${buf}${line}"$'\n'; fi
        ;;
    esac
  done < "$file"
  case "$state" in
    IN_MANAGED|IN_MANAGED_SRC) printf '%s:%d: missing\n' "$file" "$sentinel_line" >&2; stale=1;;
    IN_ART)    printf '%s:%d: unclosed-text\n' "$file" "$sentinel_line" >&2; stale=1;;
    IN_SRC)    printf '%s:%d: unclosed-mmd\n' "$file" "$sentinel_line" >&2; stale=1;;
    # SKIP_TO_CLOSE: orphan mmd already reported `missing`; silent at EOF.
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
  # Art-first (decisions/004): sentinel → ```text art → ```mmd source. The
  # same managed region inject emits, so a baked file is a valid inject
  # artifact — re-inject is idempotent, --verify is fresh. The source is a
  # post-read checksum, flat and visible below the art (no <details>).
  printf '<!-- mermaid-to-md:art -->\n```text\n%s\n```\n\n```mmd\n%s\n```\n' "$art" "$src"
} > "${outfile:-/dev/stdout}"
