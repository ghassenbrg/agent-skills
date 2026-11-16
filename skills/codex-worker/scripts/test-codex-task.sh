#!/bin/bash
# Runs codex-usage.sh and codex-task.sh (the codex-worker skill) through each way they can go, on a throwaway repository with a
# stand-in codex: its app-server answers the usage held in a file (so a test can raise it mid-run), its exec records
# its arguments and commits like a worker would. No real Codex, account or usage is touched.
set -euo pipefail

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
  GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# MARK: The stand-in codex

FAKE=$TMP/fake
mkdir -p "$FAKE"
export FAKE_DIR=$FAKE
echo "0 33" > "$FAKE/usage"          # "<5-hour used> <weekly used>", or "error"
echo "commit" > "$FAKE/exec-mode"    # commit | sleep | move-main
cat > "$FAKE/codex" <<'SH'
#!/bin/bash
case "$1" in
  --version) echo "codex-cli 0.0-test" ;;
  app-server)
    exec python3 -I -c '
import json, os, sys
d = os.environ["FAKE_DIR"]
usage = open(os.path.join(d, "usage")).read().split()
for line in sys.stdin:
    msg = json.loads(line)
    if msg.get("id") == 1:
        print(json.dumps({"id": 1, "result": {}}), flush=True)
    elif msg.get("id") == 2:
        if usage[0] == "nopercent":
            print(json.dumps({"id": 2, "result": {"rateLimits": {"primary": {"windowDurationMins": 300},
                "secondary": {"usedPercent": 1, "windowDurationMins": 10080}}}}), flush=True)
        elif usage[0] == "error":
            print(json.dumps({"id": 2, "error": {"message": "not logged in"}}), flush=True)
        else:
            w = lambda u, m: {"usedPercent": int(u), "windowDurationMins": m, "resetsAt": 1900000000}
            print(json.dumps({"id": 2, "result": {"rateLimits": {"planType": "plus",
                "primary": w(usage[0], 300), "secondary": w(usage[1], 10080)},
                "rateLimitResetCredits": {"credits": [{"status": "available"}]}}}), flush=True)
        sys.exit(0)
' ;;
  exec)
    printf '%s\n' "$@" > "$FAKE_DIR/exec-args"
    shift
    dir= out=
    while [ $# -gt 1 ]; do
      case "$1" in -C) dir=$2; shift 2 ;; -o) out=$2; shift 2 ;; *) shift ;; esac
    done
    case "$(cat "$FAKE_DIR/exec-mode")" in
      sleep-clean)   # a worker whose child ignores TERM, like a build Codex started: only a KILL to the group ends it
        echo $$ > "$FAKE_DIR/exec-pid"
        ( trap '' TERM; sleep 120 ) & echo $! > "$FAKE_DIR/child-pid"
        sleep 120 ;;
      sleep) echo partial >> "$dir/work.txt"; echo $$ > "$FAKE_DIR/exec-pid"; sleep 120 ;;
      move-main) git -C "$dir" commit -q --allow-empty -m moved; git -C "$dir" update-ref refs/heads/main HEAD ;;
      no-message) echo more >> "$dir/work.txt" ;;
      edit-runnable)   # a change that pre-commit would run unsandboxed, beside an app change and a new executable
        echo 'echo pwned' >> "$dir/scripts/ui-lint.sh"
        echo '// changed' >> "$dir/App/A.swift"
        printf '#!/bin/sh\n' > "$dir/tool"; chmod +x "$dir/tool"
        printf 'Worker commit\n' > "$(dirname "$out")/$(basename "$out" .md).commit.txt" ;;
      *) echo "done $RANDOM" >> "$dir/work.txt"
         printf 'Worker commit\n\nWhat the worker did.\n' > "$(dirname "$out")/$(basename "$out" .md).commit.txt" ;;
    esac
    echo "HANDBACK: did the work" > "$out" ;;
  *) echo "fake codex: unknown $*" >&2; exit 1 ;;
esac
SH
chmod +x "$FAKE/codex"
export CODEX_BIN=$FAKE/codex

# MARK: The throwaway repository

MAIN=$TMP/playtime
mkdir -p "$MAIN"
echo one > "$MAIN/a.txt"
mkdir -p "$MAIN/scripts" "$MAIN/App"
printf '#!/bin/sh\nexit 0\n' > "$MAIN/scripts/ui-lint.sh"; chmod +x "$MAIN/scripts/ui-lint.sh"
echo 'struct A {}' > "$MAIN/App/A.swift"
git -C "$MAIN" init -q -b main
git -C "$MAIN" add -A
git -C "$MAIN" commit -qm one
WT=$TMP/playtime-task
git -C "$MAIN" worktree add -q "$WT" -b task main
CARD=$TMP/card.md
echo "# task: a test card" > "$CARD"

PASS=0
check() {   # check <name> <expected exit> <grep pattern or -> -- command…
  local name=$1 want=$2 pat=$3; shift 4
  local out rc=0
  out=$("$@" 2>&1) || rc=$?
  if [ "$rc" != "$want" ]; then echo "FAIL $name: exit $rc, wanted $want"; echo "$out"; exit 1; fi
  if [ "$pat" != - ] && ! grep -qE -- "$pat" <<<"$out"; then echo "FAIL $name: no '$pat' in:"; echo "$out"; exit 1; fi
  PASS=$((PASS + 1))
}
TASK=$SCRIPTS/codex-task.sh

# MARK: Usage

check usage-text 0 '5-hour: +0% used' -- "$SCRIPTS/codex-usage.sh"
check usage-json 0 '"weekly": \{"used": 33' -- "$SCRIPTS/codex-usage.sh" --json
echo error > "$FAKE/usage"
check usage-error 1 'not logged in' -- "$SCRIPTS/codex-usage.sh"
echo nopercent > "$FAKE/usage"
check usage-no-percent 1 'no valid usedPercent' -- "$SCRIPTS/codex-usage.sh"
echo nopercent > "$FAKE/usage"
check task-no-percent 3 "could not read Codex's usage" -- "$TASK" "$WT" "$CARD"
check usage-no-cli 1 'not installed' -- env CODEX_BIN="$TMP/nothing" "$SCRIPTS/codex-usage.sh"
check usage-bad-arg 2 usage -- "$SCRIPTS/codex-usage.sh" --nope

# MARK: Refusals

echo "0 33" > "$FAKE/usage"
check bad-args 2 usage -- "$TASK" "$WT"
check bad-effort 2 'unknown effort' -- "$TASK" --effort huge "$WT" "$CARD"
check main-checkout 1 'main checkout' -- "$TASK" "$MAIN" "$CARD"
git -C "$MAIN" worktree add -q "$TMP/playtime-install" -b install main
check protected-dir 1 'protected folder' -- env CODEX_TASK_PROTECTED_DIRS='other *-install' "$TASK" "$TMP/playtime-install" "$CARD"
git -C "$MAIN" worktree add -q "$TMP/playtime-rel" -b release main
check protected-branch 1 'protected branch' -- env CODEX_TASK_PROTECTED_BRANCHES='main release' "$TASK" "$TMP/playtime-rel" "$CARD"
git -C "$MAIN" worktree add -q "$TMP/playtime-m" --detach main
check detached 1 'detached HEAD' -- "$TASK" "$TMP/playtime-m" "$CARD"
echo dirty > "$WT/dirty.txt"
check dirty 1 'uncommitted' -- "$TASK" "$WT" "$CARD"
rm "$WT/dirty.txt"
echo "80 33" > "$FAKE/usage"
check five-hour-limit 3 '5-hour window is 80% used' -- "$TASK" "$WT" "$CARD"
echo "10 96" > "$FAKE/usage"
check weekly-limit 3 'weekly window is 96% used' -- "$TASK" "$WT" "$CARD"
echo error > "$FAKE/usage"
check usage-unread 3 "could not read Codex's usage" -- "$TASK" "$WT" "$CARD"
echo "79 95" > "$FAKE/usage"
check dry-run 0 'workspace-write' -- "$TASK" --dry-run "$WT" "$CARD"
[ ! -e "$FAKE/exec-args" ] || { echo "FAIL dry-run ran codex"; exit 1; }

mkdir -p "$MAIN/.git/codex-task-running"
sleep 60 & LIVE=$!
echo $LIVE > "$MAIN/.git/codex-task-running/other.pid"
check parallel-limit 3 '1 Codex tasks already run' -- env CODEX_TASK_MAX_PARALLEL=1 "$TASK" "$WT" "$CARD"
kill $LIVE; wait $LIVE 2>/dev/null || true
check stale-slot-cleared 0 'Worker commit' -- env CODEX_TASK_MAX_PARALLEL=1 "$TASK" "$WT" "$CARD"
[ ! -e "$MAIN/.git/codex-task-running/other.pid" ] || { echo "FAIL stale slot kept"; exit 1; }

# MARK: A run

if ! { grep -qx 'workspace-write' "$FAKE/exec-args" && grep -qx 'sandbox_workspace_write.network_access=false' "$FAKE/exec-args" \
  && grep -qx 'approval_policy=never' "$FAKE/exec-args" && grep -qx 'gpt-6.1-terra' "$FAKE/exec-args"; } \
  || grep -q writable_roots "$FAKE/exec-args"; then
  echo "FAIL run: codex was not started sandboxed as expected:"; cat "$FAKE/exec-args"; exit 1
fi
PASS=$((PASS + 1))
[ "$(git -C "$WT" log -1 --format=%s)" = "Worker commit" ] || { echo "FAIL run: no worker commit"; exit 1; }
[ -z "$(git -C "$WT" status --porcelain)" ] || { echo "FAIL run: changes left uncommitted"; exit 1; }
grep -q HANDBACK "$WT/.codex-task/task.md" || { echo "FAIL run: no report"; exit 1; }
[ -z "$(ls "$MAIN/.git/codex-task-running")" ] || { echo "FAIL run: slot left behind"; exit 1; }
check model-effort 0 'gpt-6.1-sol, xhigh' -- "$TASK" --model gpt-6.1-sol --effort xhigh "$WT" "$CARD"
grep -qx 'model_reasoning_effort=xhigh' "$FAKE/exec-args" || { echo "FAIL effort not passed"; exit 1; }

# MARK: The watchdog and the guards after a run

echo sleep > "$FAKE/exec-mode"
echo "10 40" > "$FAKE/usage"
( sleep 4; echo "90 40" > "$FAKE/usage" ) &
START=$(date +%s)
check watchdog-stops 3 'STOPPED: .*5-hour window reached 90%' -- env CODEX_TASK_POLL=2 "$TASK" "$WT" "$CARD"
[ $(( $(date +%s) - START )) -lt 40 ] || { echo "FAIL watchdog: took too long"; exit 1; }
! kill -0 "$(cat "$FAKE/exec-pid")" 2>/dev/null || { echo "FAIL watchdog: codex still running"; exit 1; }
PASS=$((PASS + 1))

git -C "$WT" status --porcelain | grep -q . || { echo "FAIL watchdog: the stopped run's change was committed"; exit 1; }
PASS=$((PASS + 1))
git -C "$WT" checkout -q -- . && git -C "$WT" clean -qfd

# Blind is not safe: failed reads during a run stop it.
echo sleep-clean > "$FAKE/exec-mode"
echo "10 40" > "$FAKE/usage"
( sleep 4; echo error > "$FAKE/usage" ) &
check watchdog-blind 3 'could not be read 2 times in a row' -- env CODEX_TASK_POLL=2 CODEX_TASK_READ_FAILS=2 "$TASK" "$WT" "$CARD"
for p in exec-pid child-pid; do
  ! kill -0 "$(cat "$FAKE/$p")" 2>/dev/null || { echo "FAIL watchdog-blind: $p survived the stop"; exit 1; }
done
PASS=$((PASS + 1))

# The launcher interrupted: Codex and its children stop with it, and the slot is freed.
echo "10 40" > "$FAKE/usage"
rm -f "$FAKE/exec-pid" "$FAKE/child-pid"
"$TASK" "$WT" "$CARD" > "$TMP/int.out" 2>&1 & LAUNCHER=$!
for _ in $(seq 100); do [ -s "$FAKE/child-pid" ] && break; sleep 0.1; done
kill -TERM $LAUNCHER
rc=0; wait $LAUNCHER || rc=$?
for p in exec-pid child-pid; do
  ! kill -0 "$(cat "$FAKE/$p")" 2>/dev/null || { echo "FAIL interrupted: $p survived"; cat "$TMP/int.out"; exit 1; }
done
[ "$rc" = 130 ] && grep -q 'interrupted; stopping Codex' "$TMP/int.out" \
  && [ -z "$(find "$MAIN/.git/codex-task-running" -mindepth 1)" ] \
  || { echo "FAIL interrupted: exit $rc or slot left"; cat "$TMP/int.out"; ls -a "$MAIN/.git/codex-task-running"; exit 1; }
PASS=$((PASS + 1))

# Two launches at the same moment: one slot each, never past the limit, never two on one worktree.
two_at_once() {   # two_at_once <name> <max parallel> <worktree A> <worktree B> <pattern the loser prints>
  echo "10 40" > "$FAKE/usage"
  ( sleep 6; echo "95 40" > "$FAKE/usage" ) &
  local raiser=$! a b ra=0 rb=0
  env CODEX_TASK_POLL=2 CODEX_TASK_MAX_PARALLEL="$2" "$TASK" "$3" "$CARD" > "$TMP/a.out" 2>&1 & a=$!
  env CODEX_TASK_POLL=2 CODEX_TASK_MAX_PARALLEL="$2" "$TASK" "$4" "$CARD" > "$TMP/b.out" 2>&1 & b=$!
  wait $a || ra=$?; wait $b || rb=$?; wait $raiser
  local refused started
  refused=$(cat "$TMP/a.out" "$TMP/b.out" | grep -cE "REFUSED: $5" || true)
  started=$(cat "$TMP/a.out" "$TMP/b.out" | grep -c 'Codex starts on' || true)
  if [ "$ra/$rb" != 3/3 ] || [ "$refused" != 1 ] || [ "$started" != 1 ]; then
    echo "FAIL $1: exits $ra/$rb, refused $refused, started $started"; cat "$TMP/a.out" "$TMP/b.out"; exit 1
  fi
  PASS=$((PASS + 1))
}
git -C "$MAIN" worktree add -q "$TMP/playtime-task2" -b task2 main
two_at_once parallel-race 1 "$WT" "$TMP/playtime-task2" '1 Codex tasks already run'
two_at_once same-worktree-race 5 "$WT" "$WT" 'a Codex task already runs on task'
[ -z "$(find "$MAIN/.git/codex-task-running" -mindepth 1)" ] || { echo "FAIL race: slots or lock left behind"; ls -a "$MAIN/.git/codex-task-running"; exit 1; }
PASS=$((PASS + 1))

# A change to a file that runs is never committed by the script (pre-commit would run it outside the sandbox).
echo "10 40" > "$FAKE/usage"
echo edit-runnable > "$FAKE/exec-mode"
BEFORE_RUNNABLE=$(git -C "$WT" rev-parse HEAD)
check runnable-not-committed 4 'NOT COMMITTED' -- "$TASK" "$WT" "$CARD"
[ "$(git -C "$WT" rev-parse HEAD)" = "$BEFORE_RUNNABLE" ] || { echo "FAIL runnable: a commit was made"; exit 1; }
st=$(git -C "$WT" status --porcelain)
if ! { grep -q 'scripts/ui-lint.sh' <<<"$st" && grep -q 'App/A.swift' <<<"$st" && grep -q 'tool' <<<"$st"; }; then
  echo "FAIL runnable: changes not left uncommitted: $st"; exit 1
fi
PASS=$((PASS + 1))
git -C "$WT" checkout -q -- . && rm -f "$WT/tool"

echo "10 40" > "$FAKE/usage"
echo no-message > "$FAKE/exec-mode"
check no-message 0 'wrote no commit message' -- "$TASK" "$WT" "$CARD"
git -C "$WT" checkout -q -- .

echo move-main > "$FAKE/exec-mode"
check main-moved 1 'changed during the task' -- "$TASK" "$WT" "$CARD"

echo "test-codex-task: $PASS checks passed"
