#!/bin/bash
# codex-usage.sh [--json]: how much of Codex's 5-hour and weekly allowance is used, read live from the Codex CLI.
# It starts `codex app-server` on stdio and asks `account/rateLimits/read` (the numbers Codex's own /status shows). The
# CLI reads its own login; this script never opens ~/.codex itself.
#   text (default): two lines a person reads.  --json: one object for scripts:
#     {"plan":"plus","read_at":<unix>,"five_hour":{"used":0,"resets_at":<unix>},"weekly":{"used":33,"resets_at":<unix>},
#      "reset_credits":2}
#   CODEX_BIN (default codex), CODEX_USAGE_TIMEOUT (seconds, default 30)
#   exit 0 read, 1 could not read (no CLI, not logged in, no answer), 2 usage
set -u
FORMAT=text
case "${1:-}" in
  "") ;;
  --json) FORMAT=json ;;
  *) echo "usage: scripts/codex-usage.sh [--json]" >&2; exit 2 ;;
esac
CODEX=${CODEX_BIN:-codex}
command -v "$CODEX" >/dev/null 2>&1 || { echo "codex-usage: the codex CLI is not installed ('$CODEX' not found)" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "codex-usage: python3 is needed" >&2; exit 1; }

read -r -d '' PY <<'PY'
import json, subprocess, sys, time

codex, fmt, timeout = sys.argv[1], sys.argv[2], float(sys.argv[3])

def fail(msg):
    print("codex-usage: " + msg, file=sys.stderr)
    sys.exit(1)

try:
    p = subprocess.Popen([codex, "app-server"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, text=True, bufsize=1)
except OSError as e:
    fail(f"cannot start '{codex} app-server': {e}")

def send(obj):
    p.stdin.write(json.dumps(obj) + "\n")
    p.stdin.flush()

import threading
answer = {}
def reader():
    for line in p.stdout:
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        if msg.get("id") == 1 and "error" in msg:
            answer["error"] = msg["error"]
            return
        if msg.get("id") == 2:
            answer["msg"] = msg
            return
t = threading.Thread(target=reader, daemon=True)
t.start()
try:
    send({"id": 1, "method": "initialize", "params": {"clientInfo": {"name": "playtime-codex-usage", "version": "1"}}})
    send({"method": "initialized"})
    send({"id": 2, "method": "account/rateLimits/read"})
except (BrokenPipeError, OSError):
    pass
t.join(timeout)
try:
    p.stdin.close()
except OSError:
    pass
try:
    p.terminate()
    p.wait(5)
except Exception:
    p.kill()

if "error" in answer:
    fail(f"codex app-server refused: {answer['error']}")
msg = answer.get("msg")
if msg is None:
    fail(f"no answer from '{codex} app-server' within {timeout:.0f} s")
if "error" in msg:
    fail(f"could not read the limits (logged in to Codex?): {msg['error'].get('message', msg['error'])}")
res = msg.get("result") or {}
rl = res.get("rateLimits") or {}
windows = {}
for key in ("primary", "secondary"):
    w = rl.get(key)
    if not w:
        continue
    mins = w.get("windowDurationMins")
    name = "five_hour" if mins == 300 else "weekly" if mins == 10080 else f"{mins}min"
    used = w.get("usedPercent")
    if isinstance(used, bool) or not isinstance(used, (int, float)) or not 0 <= used <= 100:
        fail(f"the {name} window has no valid usedPercent: {json.dumps(w)[:200]}")
    windows[name] = {"used": int(round(used)), "resets_at": w.get("resetsAt")}
if "five_hour" not in windows or "weekly" not in windows:
    fail(f"the answer has no 5-hour and weekly windows: {json.dumps(rl)[:300]}")
credits = [c for c in ((res.get("rateLimitResetCredits") or {}).get("credits") or []) if c.get("status") == "available"]
now = int(time.time())
out = {"plan": rl.get("planType"), "read_at": now, "five_hour": windows["five_hour"], "weekly": windows["weekly"],
       "reset_credits": len(credits), "limit_reached": rl.get("rateLimitReachedType")}

if fmt == "json":
    print(json.dumps(out))
    sys.exit(0)

def when(ts):
    if not ts:
        return "unknown"
    left = max(0, ts - now)
    fmt_ = "%H:%M" if left < 20 * 3600 else "%a %H:%M"
    return f"{time.strftime(fmt_, time.localtime(ts))} (in {left // 3600}h{left % 3600 // 60:02d})"

print(f"Codex usage ({out['plan'] or 'unknown plan'}), read {time.strftime('%Y-%m-%d %H:%M %Z', time.localtime(now))}")
print(f"  5-hour: {out['five_hour']['used']:3d}% used, resets {when(out['five_hour']['resets_at'])}")
print(f"  weekly: {out['weekly']['used']:3d}% used, resets {when(out['weekly']['resets_at'])}")
if out["reset_credits"]:
    print(f"  reset credits: {out['reset_credits']} available (never used by a script; the user's call)")
if out["limit_reached"]:
    print(f"  LIMIT REACHED: {out['limit_reached']}")
PY

exec python3 -I -c "$PY" "$CODEX" "$FORMAT" "${CODEX_USAGE_TIMEOUT:-30}"
