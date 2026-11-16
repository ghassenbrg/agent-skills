#!/bin/bash
# codex-task.sh [--dry-run] [--model M] [--effort E] <worktree> <card.md>: hand one small task card to Codex (the
# ChatGPT models through the local codex CLI), inside a usage budget. Part of the codex-worker skill.
#
# The lead (the Claude session that owns the work) makes a worktree and branch for the task and writes the card. Then:
#   1. refuses an unsafe place: the main checkout, a detached HEAD, a protected branch (CODEX_TASK_PROTECTED_BRANCHES,
#      default "main master"), a worktree whose folder name matches CODEX_TASK_PROTECTED_DIRS (shell globs, default
#      none), a worktree with uncommitted changes, or one that already has a Codex task running;
#   2. reads Codex's usage live (codex-usage.sh) and refuses (exit 3) when the 5-hour window is at or above
#      CODEX_TASK_MAX_5H (default 80) or the weekly one at or above CODEX_TASK_MAX_WEEK (default 96), or when it cannot
#      read them. Image generation and every other Codex use share the 5-hour window, so the start limit sits below
#      the stop limit;
#   3. refuses when CODEX_TASK_MAX_PARALLEL (default 2) Codex tasks already run for this repository;
#   4. runs `codex exec` in the worktree: sandbox workspace-write (writes only there; Codex keeps every .git folder
#      read-only, so it can neither commit nor move a ref), no network (so no push), approvals off (it cannot ask its
#      way out), the card and the rules as the prompt. Codex reads the project's AGENTS.md itself;
#   5. while Codex runs, reads the usage every CODEX_TASK_POLL seconds (default 120) and stops the task (exit 3) the
#      moment the 5-hour window reaches CODEX_TASK_STOP_5H (default 90), or after CODEX_TASK_READ_FAILS (default 3)
#      failed reads in a row: blind is not safe;
#   6. checks that the protected branches, their origin copies, the tags and the repo's git config did not change;
#   7. commits what Codex changed, outside the sandbox and through the repo's git hooks, with the message Codex wrote
#      to .codex-task/<branch>.commit.txt (a hook that refuses leaves the change uncommitted, and says so). It never
#      commits a change to a file that runs (scripts, hooks, build files, agent config, git files, executables,
#      symlinks; add globs with CODEX_TASK_RUNNABLE_EXTRA): hooks would run Codex's code unsandboxed. It lists those
#      files and exits 4, and the lead reads that diff first.
# Codex's report: .codex-task/<branch>.md in the worktree (kept out of git by .git/info/exclude), its log beside it.
#   --model / CODEX_TASK_MODEL (default gpt-6.1-terra; gpt-6.1-sol for harder cards), --effort / CODEX_TASK_EFFORT
#   (default high; low, medium, high, xhigh, max), CODEX_BIN, CODEX_TASK_TIMEOUT (seconds, default 5400),
#   CODEX_TASK_NO_RUN (what Codex must not run, default "the project's full build, test or release gates")
#   exit 0 ran, 1 failed, 2 usage, 3 refused or stopped by the usage budget or the parallel limit, 4 ran but left
#   uncommitted because it changed a file that runs (the lead reads the diff)
set -u
DRY=0
MODEL=${CODEX_TASK_MODEL:-gpt-6.1-terra}
EFFORT=${CODEX_TASK_EFFORT:-high}
USAGE_LINE="usage: scripts/codex-task.sh [--dry-run] [--model M] [--effort E] <worktree> <card.md>"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --model) [ $# -ge 2 ] || { echo "$USAGE_LINE" >&2; exit 2; }; MODEL=$2; shift 2 ;;
    --effort) [ $# -ge 2 ] || { echo "$USAGE_LINE" >&2; exit 2; }; EFFORT=$2; shift 2 ;;
    -*) echo "$USAGE_LINE" >&2; exit 2 ;;
    *) break ;;
  esac
done
[ $# = 2 ] || { echo "$USAGE_LINE" >&2; exit 2; }
case "$EFFORT" in low|medium|high|xhigh|max|ultra) ;; *) echo "codex-task: unknown effort '$EFFORT'" >&2; exit 2 ;; esac
[[ $MODEL =~ ^[A-Za-z0-9._-]+$ ]] || { echo "codex-task: bad model name '$MODEL'" >&2; exit 2; }
fail() { echo "codex-task: $*" >&2; exit 1; }
refuse() { echo "codex-task: REFUSED: $*" >&2; exit 3; }

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
CODEX=${CODEX_BIN:-codex}
MAX_5H=${CODEX_TASK_MAX_5H:-80}
STOP_5H=${CODEX_TASK_STOP_5H:-90}
MAX_WEEK=${CODEX_TASK_MAX_WEEK:-96}
MAX_PAR=${CODEX_TASK_MAX_PARALLEL:-2}
POLL=${CODEX_TASK_POLL:-120}
READ_FAILS=${CODEX_TASK_READ_FAILS:-3}
for n in "$MAX_5H" "$STOP_5H" "$MAX_WEEK" "$MAX_PAR" "$POLL" "$READ_FAILS"; do [[ $n =~ ^[0-9]+$ ]] || fail "limits must be whole numbers"; done

# MARK: The place

[ -d "$1" ] || fail "no worktree at $1"
WT=$(cd "$1" && pwd -P)
[ -f "$2" ] || fail "no card at $2"
CARD=$(cd "$(dirname "$2")" && pwd -P)/$(basename "$2")
TOP=$(git -C "$WT" rev-parse --show-toplevel 2>/dev/null) || fail "$WT is not a git checkout"
[ "$(cd "$TOP" && pwd -P)" = "$WT" ] || fail "$WT is not the top of its checkout ($TOP)"
COMMON=$(cd "$WT" && cd "$(git rev-parse --git-common-dir)" && pwd -P) || fail "no git directory for $WT"
[ "$(git -C "$WT" rev-parse --absolute-git-dir)" != "$COMMON" ] || fail "$WT is the main checkout; Codex works only in a worktree of its own"
PROTECTED=${CODEX_TASK_PROTECTED_BRANCHES:-main master}
for g in ${CODEX_TASK_PROTECTED_DIRS:-}; do
  # shellcheck disable=SC2254
  case "$(basename "$WT")" in $g) fail "$WT is a protected folder ($g); never a work place" ;; esac
done
BRANCH=$(git -C "$WT" symbolic-ref -q --short HEAD) || fail "$WT has a detached HEAD; make a branch for the task"
for b in $PROTECTED; do [ "$BRANCH" != "$b" ] || fail "Codex never works on $BRANCH (a protected branch)"; done
[ -z "$(git -C "$WT" status --porcelain)" ] || fail "$WT has uncommitted changes; commit them (the card too) or start clean"

OUT_DIR=$WT/.codex-task                                # kept out of git by the repo's info/exclude
NAME=${BRANCH//\//-}
OUT=$OUT_DIR/$NAME.md
LOG=$OUT_DIR/$NAME.log
MSG=$OUT_DIR/$NAME.commit.txt
SLOTS=$COMMON/codex-task-running                       # one folder for every worktree of this repo

# MARK: The budget

USAGE=$(CODEX_BIN=$CODEX "$SCRIPTS/codex-usage.sh" --json) || refuse "could not read Codex's usage, so no task starts"
read -r U5 UW <<<"$(python3 -I -c 'import json,sys; d=json.loads(sys.argv[1]); print(d["five_hour"]["used"], d["weekly"]["used"])' "$USAGE" 2>/dev/null)"
[[ ${U5:-} =~ ^[0-9]+$ && ${UW:-} =~ ^[0-9]+$ ]] || refuse "could not read Codex's usage answer: $USAGE"
[ "$U5" -lt "$MAX_5H" ] || refuse "Codex's 5-hour window is ${U5}% used (start limit ${MAX_5H}%)"
[ "$UW" -lt "$MAX_WEEK" ] || refuse "Codex's weekly window is ${UW}% used (limit ${MAX_WEEK}%)"
echo "codex-task: usage 5-hour ${U5}%, weekly ${UW}% (start below ${MAX_5H}% / ${MAX_WEEK}%; stops at 5-hour ${STOP_5H}%)"

# MARK: The prompt

TIP=$(git -C "$WT" rev-parse HEAD)
NO_RUN=${CODEX_TASK_NO_RUN:-"the full build, test or release gates of the project"}
PROMPT="You are a worker agent. Your task card is below. Follow the project's AGENTS.md (or CLAUDE.md) in this checkout;
where it speaks of your lead, that is the session that started you.

- Work only in $WT, on the branch '$BRANCH' (now at ${TIP:0:12}). Never switch branch, never touch another worktree,
  never edit a protected branch ($PROTECTED), never push, merge, tag, rebase or reset, never deploy or install
  anything. Change only the files the card allows.
- You cannot commit: the sandbox keeps .git read-only. Do not try git add or git commit. When you are done, write the
  commit message to $MSG (a subject line under 72 characters, a blank line, then a short body; no Co-Authored-By or
  AI attribution line). Your lead commits all your changes in this worktree with it, so leave no stray files.
- A change to a script, hook, build file, Makefile, package manifest, project file or agent config is never
  committed for you: your lead must read it first, so make one only if the card asks.
- Do not run $NO_RUN: your lead runs the gates after you.
  You may run quick checks that stay inside this worktree (a lint, a single fast test, reading files, git
  log/diff/show). If the sandbox stops a command, do not work around it; say so in your report.
- If the card is unclear or too big for you, stop and say what is missing instead of guessing.
- End with a report for your lead, titled HANDBACK (never MERGE-READY: the lead sends that after the gates): the
  commits you made, the files changed, each acceptance item with what you did for it, what you checked and how, and a
  'not verified' list.

The card ($CARD):

$(cat "$CARD")"

CMD=("$CODEX" exec --sandbox workspace-write -c approval_policy=never
  -c sandbox_workspace_write.network_access=false
  -c "model_reasoning_effort=$EFFORT" -m "$MODEL"
  --color never -C "$WT" -o "$OUT" "$PROMPT")

if [ "$DRY" = 1 ]; then
  echo "codex-task: dry run; would run in $WT on $BRANCH:"
  printf '  %q' "${CMD[@]:0:$((${#CMD[@]} - 1))}"; echo ' <prompt>'
  echo "--- prompt ---"; echo "$PROMPT"
  exit 0
fi

# MARK: A slot (at most MAX_PAR tasks at once, one per worktree)

mkdir -p "$SLOTS" "$OUT_DIR" || fail "cannot make $SLOTS or $OUT_DIR"
grep -qx '/.codex-task/' "$COMMON/info/exclude" 2>/dev/null || { mkdir -p "$COMMON/info" && echo '/.codex-task/' >> "$COMMON/info/exclude"; } \
  || fail "cannot keep .codex-task out of git ($COMMON/info/exclude)"
# Taking a slot is one step under a lock (mkdir is atomic), so two launches at the same moment can't both pass the
# count. A lock whose holder is gone is taken over.
LOCK=$SLOTS/.lock
tries=0
until mkdir "$LOCK" 2>/dev/null; do
  holder=$(cat "$LOCK/pid" 2>/dev/null)
  if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$LOCK"; continue; fi
  tries=$((tries + 1))
  [ $tries -lt 100 ] || fail "the slot lock $LOCK is held (pid ${holder:-?}) for over 20 s"
  sleep 0.2
done
echo $$ > "$LOCK/pid"
for f in "$SLOTS"/*.pid; do
  [ -e "$f" ] || continue
  kill -0 "$(cat "$f" 2>/dev/null)" 2>/dev/null || rm -f "$f"   # a slot whose task is gone
done
SLOT_ERR=""
RUNNING=$(find "$SLOTS" -maxdepth 1 -name '*.pid' | wc -l | tr -d ' ')
if [ -e "$SLOTS/$NAME.pid" ]; then SLOT_ERR="a Codex task already runs on $BRANCH (pid $(cat "$SLOTS/$NAME.pid"))"
elif [ "$RUNNING" -ge "$MAX_PAR" ]; then SLOT_ERR="$RUNNING Codex tasks already run (limit $MAX_PAR)"
else echo $$ > "$SLOTS/$NAME.pid"
fi
rm -rf "$LOCK"
[ -z "$SLOT_ERR" ] || refuse "$SLOT_ERR"
trap 'rm -f "$SLOTS/$NAME.pid"' EXIT

# MARK: The run

snapshot() {
  local b refs=()
  for b in $PROTECTED; do refs+=("refs/heads/$b" "refs/remotes/origin/$b"); done
  git -C "$WT" for-each-ref --format='%(refname) %(objectname)' "${refs[@]}" refs/tags
  git config --file "$COMMON/config" --list 2>/dev/null
}
BEFORE=$(snapshot)
rm -f "$OUT" "$MSG"
echo "codex-task: Codex starts on $BRANCH in $WT ($MODEL, $EFFORT; $("$CODEX" --version 2>/dev/null | head -1)); log $LOG"
# with-timeout runs Codex in a process group of its own, whose id is with-timeout's child's pid. Its id is taken once,
# at the start: after a TERM the leader may exit while commands it started live on, and only the group id still
# reaches them.
RUN="" GROUP=""
stop_run() {
  [ -n "$GROUP" ] || GROUP=$(pgrep -P "$RUN" | head -1)
  [ -n "$GROUP" ] || return 0
  kill -TERM -"$GROUP" 2>/dev/null || return 0

  for _ in 1 2 3 4 5; do kill -0 -"$GROUP" 2>/dev/null || break; sleep 1; done
  kill -KILL -"$GROUP" 2>/dev/null
  wait "$RUN" 2>/dev/null
}
# The launcher stopped (Ctrl-C, a kill, the terminal closed): stop Codex with it, so no worker runs outside a slot.
on_signal() {
  echo "codex-task: interrupted; stopping Codex" >&2
  [ -z "$RUN" ] || stop_run
  exit 130
}
trap on_signal INT TERM HUP
"$SCRIPTS/with-timeout" "${CODEX_TASK_TIMEOUT:-5400}" "${CMD[@]}" > "$LOG" 2>&1 &
RUN=$!
for _ in $(seq 50); do GROUP=$(pgrep -P "$RUN" | head -1); [ -z "$GROUP" ] || break; sleep 0.1; done
STOPPED=""
FAILS=0
while kill -0 "$RUN" 2>/dev/null; do
  waited=0
  while [ $waited -lt "$POLL" ] && kill -0 "$RUN" 2>/dev/null; do sleep 2; waited=$((waited + 2)); done
  kill -0 "$RUN" 2>/dev/null || break
  NOW5=$(CODEX_BIN=$CODEX "$SCRIPTS/codex-usage.sh" --json 2>/dev/null \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["five_hour"]["used"])' 2>/dev/null)
  if [[ ${NOW5:-} =~ ^[0-9]+$ ]]; then
    FAILS=0
    [ "$NOW5" -ge "$STOP_5H" ] && STOPPED="Codex's 5-hour window reached ${NOW5}% (stop limit ${STOP_5H}%)"
  else
    FAILS=$((FAILS + 1))   # blind is not safe: after a few failed reads in a row, stop
    [ "$FAILS" -lt "$READ_FAILS" ] || STOPPED="Codex's usage could not be read $FAILS times in a row"
  fi
  if [ -n "$STOPPED" ]; then
    echo "codex-task: STOPPING: $STOPPED" >&2
    stop_run
    break
  fi
done
wait "$RUN"
rc=$?

[ "$(snapshot)" = "$BEFORE" ] || fail "FAILED: a protected branch, its origin copy, a tag or the git config changed during the task. Before and after:
$(diff <(printf '%s\n' "$BEFORE") <(snapshot))"

echo "codex-task: codex exited $rc$( [ $rc = 124 ] && echo ' (timed out)')"
[ "$(git -C "$WT" rev-parse HEAD)" = "$TIP" ] || echo "WARNING: $BRANCH moved during the task (Codex should not commit)"
# Committing runs the repo's hooks outside the sandbox, and pre-commit runs scripts from this very checkout
# (lints, checks). So a change to anything that runs (scripts, hooks, build files, agent config, git files, an
# executable or a symlink) is never committed here: the lead reads that diff first.
RUNNABLE=""
if [ -z "$STOPPED" ] && [ -n "$(git -C "$WT" status --porcelain)" ]; then
  RUNNABLE=$(git -C "$WT" status --porcelain=v1 -z --untracked-files=all | python3 -I -c '
import fnmatch, os, sys
wt = sys.argv[1]
fields = sys.stdin.buffer.read().split(b"\0")
paths, i = [], 0
while i < len(fields):
    entry = fields[i].decode("utf-8", "surrogateescape")
    i += 1
    if len(entry) < 4:
        continue
    paths.append(entry[3:])
    if entry[0] in "RC" and i < len(fields):          # a rename or copy: its source path follows
        paths.append(fields[i].decode("utf-8", "surrogateescape")); i += 1
RUNS = ["scripts/*", "*/scripts/*", "bin/*", "tools/*", "hooks/*", "*/hooks/*", ".husky/*", ".github/*",
        "Makefile", "*/Makefile", "*.mk", "Justfile", "Taskfile*", "Dockerfile*", "*/Dockerfile*",
        "*.sh", "*.bash", "*.zsh", "*.py", "*.pl", "*.rb", "*.js", "*.mjs", "*.cjs", "*.ts", "*.command", "*.ps1",
        "package.json", "*/package.json", "*lock.json", "*.lock", "pyproject.toml", "setup.py", "setup.cfg", "tox.ini",
        "noxfile.py", "conftest.py", "*/conftest.py", "Cargo.toml", "*/Cargo.toml", "build.rs", "go.mod",
        "Package.swift", "*/Package.swift", "Package.resolved", "*/Package.resolved", "*.xcodeproj/*", "*.xcworkspace/*",
        "*.xcscheme", "*.xcconfig", "*.gradle", "*.gradle.kts", "gradlew", "*/gradlew", "gradle/*",
        ".claude/*", ".agents/*", ".codex/*", ".cursor/*", ".vscode/*", ".envrc", ".env*",
        ".git*", "*/.git*", "CLAUDE.md", "AGENTS.md", "*/CLAUDE.md", "*/AGENTS.md"] + sys.argv[2].split()
for p in sorted(set(paths)):
    full = os.path.join(wt, p)
    why = next((g for g in RUNS if fnmatch.fnmatch(p, g)), None)
    if why is None and os.path.islink(full):
        why = "a symlink"
    elif why is None and os.path.isfile(full) and os.access(full, os.X_OK):
        why = "executable"
    if why:
        print(f"  {p}  ({why})")
' "$WT" "${CODEX_TASK_RUNNABLE_EXTRA:-}")
fi
if [ -n "$RUNNABLE" ]; then
  echo "codex-task: NOT COMMITTED: Codex changed files that run outside the sandbox when committed or gated:"
  echo "$RUNNABLE"
  echo "codex-task: read that diff yourself (git -C $WT diff; git -C $WT status) before committing or running any gate"
elif [ -z "$STOPPED" ] && [ -n "$(git -C "$WT" status --porcelain)" ]; then
  if [ -s "$MSG" ]; then
    if git -C "$WT" add -A && git -C "$WT" commit -q -F "$MSG"; then
      echo "codex-task: committed Codex's change on $BRANCH"
    else
      git -C "$WT" reset -q
      echo "WARNING: the commit was refused (see above); the change is left uncommitted for the lead"
    fi
  else
    echo "WARNING: Codex wrote no commit message ($MSG); the change is left uncommitted for the lead"
  fi
fi
echo "--- commits on $BRANCH since ${TIP:0:12} ---"
git -C "$WT" log --oneline "$TIP..HEAD"
[ "$(git -C "$WT" symbolic-ref -q --short HEAD)" = "$BRANCH" ] || echo "WARNING: $WT is no longer on $BRANCH"
DIRTY=$(git -C "$WT" status --porcelain)
[ -z "$DIRTY" ] || { echo "--- left uncommitted ---"; echo "$DIRTY"; }
echo "--- Codex's report: $OUT ---"
[ -s "$OUT" ] && cat "$OUT" || echo "(none; see $LOG)"
echo "---"
CODEX_BIN=$CODEX "$SCRIPTS/codex-usage.sh" 2>/dev/null || true
[ -z "$STOPPED" ] || { echo "codex-task: STOPPED: $STOPPED; the branch keeps what Codex committed" >&2; exit 3; }
[ -z "$RUNNABLE" ] || exit 4
[ $rc = 0 ] && [ -s "$OUT" ] || exit 1
