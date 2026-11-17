---
name: codex-worker
description: Hand small, well-scoped coding tasks from a Claude session to Codex (the ChatGPT models through the local codex CLI) so they get done on Codex's allowance instead of Claude's tokens, inside a usage budget that never lets Codex's 5-hour window run dry for image generation or other Codex use. Covers reading Codex's live 5-hour and weekly usage (scripts/codex-usage.sh), choosing which tasks suit Codex and which model and effort, the one sandboxed launch command (scripts/codex-task.sh), and the lead's diff review, gates and code review before anything moves on. Use when the user wants to offload work to Codex or ChatGPT, use up weekly Codex allowance before it resets, or asks how much Codex usage is left. Pair it with the project's own skill when there is one (Playtime: hand-to-codex). Not for Codex reviewing code, nor for images (codex-imagegen).
---

# Codex as a worker

Codex is a second pair of hands with its own allowance. The Claude session that hands it a task (the lead) stays
responsible: it picks the task, starts it, reads the diff, runs the gates and reviews before anything moves on. A
project skill (Playtime: `hand-to-codex`) adds that project's rules and command paths; read it too when it exists.

Requires the Codex CLI, logged in, and `python3`. The scripts are in `scripts/` beside this file.

## 1. Check the budget

```sh
S=~/.claude/skills/codex-worker/scripts
$S/codex-usage.sh          # 5-hour and weekly used %, reset times, reset credits
$S/codex-usage.sh --json   # the same for scripts
```

It starts `codex app-server` and asks `account/rateLimits/read`, the same numbers as Codex's `/status`. It never opens
`~/.codex` itself.

- **The 5-hour window is the hard one.** Every Codex use on the account shares it (image generation, reviews, other
  sessions). `codex-task.sh` starts nothing at or above **80%** and stops a running task at **90%**
  (`CODEX_TASK_MAX_5H`, `CODEX_TASK_STOP_5H`). Only the user changes those limits.
- **The weekly window:** nothing starts at or above 96%. Allowance left near the weekly reset is lost, so that's when
  to run more tasks, or Sol at higher effort, while the 5-hour window has room.
- **Rate-limit reset credits** are the user's to spend. Never use one.
- When images and tasks run together, keep image jobs to about 3 in parallel: Codex caps queued generations ("too many
  content generations queued").

## 2. Choose a task Codex can finish

Good:
- docs, strings, lint fixes;
- a test for existing behaviour, a small bug fix with a repro;
- self-contained logic with tests to write, the files named;
- mechanical sweeps with a clear finish line.

Keep for Claude:
- design, art, anything judged by eye or against approved images, UI work that needs a simulator or browser;
- security, infra, deploys, releases, anything touching money or accounts;
- work that needs the user's input, big or fuzzy tasks.

Write the task as a card: one goal, the files allowed, acceptance items a test or a command can check, out of scope.
Codex can't run heavy gates in its sandbox, so leave those to you.

## 3. Pick the model and effort

| Task | Model | Effort |
|---|---|---|
| docs, strings, mechanical sweeps | `gpt-6.1-terra` (default) | `medium` |
| a small fix or a test (default) | `gpt-6.1-terra` | `high` |
| logic, diagnosis, a careful larger card | `gpt-6.1-sol` | `high`, or `xhigh` |

`codex debug models` lists the models. Sol and higher effort use more of the 5-hour window.

## 4. Start it

```sh
git worktree add ../<repo>-<name> -b <branch> origin/main       # a worktree of its own, clean
$S/codex-task.sh --dry-run ../<repo>-<name> <card.md>            # see the prompt and the checks
$S/codex-task.sh [--model gpt-6.1-sol] [--effort xhigh] ../<repo>-<name> <card.md>   # in the background
```

Per project, set `CODEX_TASK_PROTECTED_BRANCHES` (default `main master`), `CODEX_TASK_PROTECTED_DIRS` (worktree folder
globs that must never be work places), `CODEX_TASK_NO_RUN` (what Codex must not run), `CODEX_TASK_RUNNABLE_EXTRA`
(more globs of files that run). The project skill gives the values.

What the script guarantees:
- **No unsafe place.** It refuses the main checkout, a protected branch or folder, a detached HEAD, a dirty worktree,
  and more than 2 tasks at once (`CODEX_TASK_MAX_PARALLEL`, taken under a lock).
- **Sandboxed.** Codex can write only inside the worktree, has no network and can't ask for more. Its sandbox keeps
  `.git` read-only, so Codex writes `.codex-task/<branch>.commit.txt` and the script commits through the hooks
  afterwards.
- **Never commits code that would run unreviewed.** A change to a file that runs (scripts, hooks, build files,
  manifests, agent config, git files, executables, symlinks) is listed, everything is left uncommitted, and it exits 4.
  The hooks or the gates would run that code with your rights.
- **Budget watched.** It reads usage every 2 minutes and stops the whole process group at the stop limit or after 3
  failed reads; an interrupted launcher stops Codex too.
- **Independent of where it started.** It copies its helpers to a private temporary folder at start, so the folder
  it was launched from (often a worktree) may be removed while the task runs.
- **Refs checked.** It fails loudly if a tag or the git config changed (branch entries aside: worktrees add them), or if
  a protected branch or its origin copy was deleted, rewritten or given Codex's commits. A protected branch that only
  moved forward (you landed something meanwhile) is printed as a NOTE: check it was you.

Codex's HANDBACK is in `.codex-task/<branch>.md`, its log beside it. Exit codes: 0 ran, 1 failed, 2 bad arguments,
3 refused or stopped by the budget, 4 left uncommitted (a file that runs changed).

## 5. Check what it delivered

The HANDBACK is a claim, not evidence.
1. **Read the diff before any gate runs it.** Gates and hooks execute the branch's scripts and tests with your rights.
   After exit 4, read every listed file, then commit it yourself or drop it.
2. Run the project's gates yourself on the branch.
3. Review it as a reviewer who didn't write it (the project's review checklist if it has one). Send problems back to
   Codex with a short card of fixes, or fix them yourself; after two failed rounds take the task back.
4. Report it as "written by Codex (<model>, <effort>), gated and reviewed by <you>".

## Keep this skill improving (every use)

This skill is meant to get better each time it's used. When a run teaches something, update it before you report the
task done:
- **A gap or a wrong line here:** fix it in `~/git/agent-skills/skills/codex-worker/` (this folder; `~/.claude/skills/`
  links to it). Add a dated 1-2 line entry to `LESSONS.md` (what happened, what to do), and change the rule or script
  when the lesson is a rule.
- **A script bug:** fix it with a case in `scripts/test-codex-task.sh` that fails before the fix, and run the test.
  Port the fix to a project's own copy too (Playtime keeps one in `scripts/` with its own gate).
- **Project-only lessons** go in the project skill (Playtime: `hand-to-codex` in the repo).
- **Numbers worth keeping:** what a task of a given size, model and effort used of the 5-hour window. That's how the
  limits get tuned.

Commit the change in `~/git/agent-skills` with a plain message, scan it for secrets, device ids and personal details
(the repo is public), and push it.
