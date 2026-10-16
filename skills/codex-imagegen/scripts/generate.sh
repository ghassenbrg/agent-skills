#!/usr/bin/env bash
# Generate one PNG image through Codex's built-in image_gen tool and save it to an exact path.
#
# Usage:
#   generate.sh --out PATH.png [--ref IMAGE]... [--overwrite] [--sol | --model NAME] [--effort LEVEL] [--keep-logs] [--] "image brief"
#
# Codex (gpt-6-luna, xhigh effort) only generates; this script collects the image from that run. --sol uses gpt-6.1-sol.
# Prints the saved path and image info on success; exits non-zero with diagnostics on failure.
set -euo pipefail

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-2}"
}
die() { echo "error: $*" >&2; exit 2; }
is_png() { [[ -s "$1" && "$(head -c 8 "$1" | od -An -tx1 | tr -d ' \n')" == 89504e470d0a1a0a ]]; }
lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

out="" overwrite=0 keep_logs=0
model="${CODEX_IMAGEGEN_MODEL:-gpt-6-luna}"
effort="${CODEX_IMAGEGEN_EFFORT:-xhigh}"
refs=() words=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out) [[ $# -ge 2 ]] || die "$1 needs a value"; out="$2"; shift 2 ;;
    -r|--ref) [[ $# -ge 2 ]] || die "$1 needs a value"; refs+=("$2"); shift 2 ;;
    --overwrite) overwrite=1; shift ;;
    -m|--model) [[ $# -ge 2 ]] || die "$1 needs a value"; model="$2"; shift 2 ;;
    --sol) model="gpt-6.1-sol"; shift ;;
    -e|--effort) [[ $# -ge 2 ]] || die "$1 needs a value"; effort="$2"; shift 2 ;;
    --keep-logs) keep_logs=1; shift ;;
    -h|--help) usage 0 ;;
    --) shift; words+=("$@"); break ;;
    -*) die "unknown option $1 (put the brief after -- if it starts with '-')" ;;
    *) words+=("$1"); shift ;;
  esac
done
brief="${words[*]+"${words[*]}"}"

[[ -n "$out" && -n "$brief" ]] || usage >&2
command -v codex >/dev/null || { echo "error: codex CLI not found (npm i -g @openai/codex, then codex login)" >&2; exit 1; }
[[ "$(lower "$out")" == *.png ]] || die "--out must end in .png (convert afterwards if another format is needed)"
[[ -d "$out" ]] && die "$out is a directory"
if [[ -e "$out" && $overwrite -eq 0 ]]; then
  echo "error: $out already exists (pass --overwrite to replace it, or pick a new name like name-v2.png)" >&2
  exit 1
fi
for ref in ${refs[@]+"${refs[@]}"}; do
  [[ -f "$ref" ]] || die "reference image not found: $ref"
  case "$(lower "$ref")" in *.png|*.jpg|*.jpeg|*.webp) ;; *) die "reference must be PNG, JPEG, or WebP: $ref" ;; esac
done
[[ "$out" == /* ]] || out="$PWD/$out"

ref_note=""
ref_args=()
if [[ ${#refs[@]} -gt 0 ]]; then
  ref_note="The attached image(s) are references; follow the brief for how to use them (style, subject, or edit target)."
  for ref in "${refs[@]}"; do ref_args+=(-i "$ref"); done
fi

# Codex only generates; it never saves. Codex itself stores every generation under generated_images/<thread id>/,
# and this script copies the run's own image from there (no base64 round-trips, no other job's image).
log_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-imagegen.XXXXXX")"
new="$log_dir/new.png"

prompt="Call your built-in image_gen tool exactly once (not the CLI/API fallback) to generate the image below.
${ref_note}

Brief:
${brief}

The image is collected automatically once generated: do not save, copy, move or inspect any files and do not run shell
commands. Do not generate a second image. Do not ask questions; make reasonable choices. When the image is generated,
reply with only: DONE"

set +e
codex exec --skip-git-repo-check --ephemeral \
  -s read-only -C "$log_dir" \
  -m "$model" -c model_reasoning_effort="$effort" \
  --json -o "$log_dir/last-message.txt" \
  ${ref_args[@]+"${ref_args[@]}"} -- "$prompt" \
  </dev/null >"$log_dir/events.jsonl" 2>"$log_dir/stderr.txt"
status=$?
set -e

thread_id="$(grep -o '"thread_id":"[^"]*"' "$log_dir/events.jsonl" | head -1 | cut -d'"' -f4 || true)"
gen_dir="${CODEX_HOME:-$HOME/.codex}/generated_images/$thread_id"
own=()
if [[ -n "$thread_id" && -d "$gen_dir" ]]; then
  while IFS= read -r f; do own+=("$f"); done < <(ls -t "$gen_dir"/*.png 2>/dev/null || true)
fi
if [[ ${#own[@]} -gt 0 ]]; then
  cp "${own[0]}" "$new"
  if [[ ${#own[@]} -gt 1 ]]; then
    echo "warning: Codex generated ${#own[@]} images in this run; using the last one (all in $gen_dir)" >&2
  fi
fi

if ! is_png "$new"; then
  echo "error: Codex did not produce a valid PNG (codex exit $status); $out was not touched" >&2
  echo "--- codex last message:" >&2; cat "$log_dir/last-message.txt" >&2 2>/dev/null || true
  echo "--- codex stderr (tail):" >&2; tail -20 "$log_dir/stderr.txt" >&2 || true
  echo "--- full logs: $log_dir" >&2
  exit 1
fi

{ mkdir -p "$(dirname "$out")" && mv -f "$new" "$out"; } ||
  { echo "error: could not write $out; the generated image is kept at $new" >&2; exit 1; }
if [[ $keep_logs -eq 1 ]]; then echo "logs:  $log_dir"; else rm -rf "$log_dir"; fi
echo "saved: $out ($model, $effort)"
if command -v file >/dev/null; then
  echo "info:  $(file -b "$out"), $(du -h "$out" | cut -f1 | tr -d ' ')"
else
  echo "info:  PNG, $(du -h "$out" | cut -f1 | tr -d ' ')"
fi
