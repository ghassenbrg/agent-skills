# codex-worker lessons

Dated, 1-2 lines each: what happened, what to do. A lesson that is a rule also goes into SKILL.md or a script.

- 2026-11-17 Codex's sandbox keeps every `.git` folder read-only, even one named in `writable_roots`: a worker can't
  commit (`index.lock` denied). The launcher commits after the run, outside the sandbox.
- 2026-11-17 Committing outside the sandbox runs the repo's hooks, and hooks run scripts from the checkout Codex just
  edited. Never commit a Codex change to a file that runs; the lead reads it first (exit 4).
- 2026-11-17 Watchdogs fail open unless told otherwise: stop after a few failed usage reads, take the process-group id
  at start (the leader may exit before its children), and stop Codex when the launcher itself is interrupted.
- 2026-11-17 Cost seen: a one-file card on gpt-6.1-terra at low effort used about 25k tokens, about 1% of the 5-hour
  window (Plus plan). A read-only branch review at high effort used about 3%.
- 2026-11-17 Image generation on the same account (Playtime, 7-17 Nov): 330 images, 99.4% gpt-6-luna at xhigh, at
  most about 55 in 5 hours, never ran the 5-hour window dry. The one limit hit was the queue cap on parallel generations.
- 2026-11-17 Two Codex review rounds and one Claude review each found real defects in this launcher. Run a
  cross-review on any change to the scripts.
- 2026-11-17 First real run of this generic launcher (scratch repo, gpt-6.1-terra low): one-line card committed, `.codex-task/` stayed out of git.
