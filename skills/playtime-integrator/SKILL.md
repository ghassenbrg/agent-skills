---
name: playtime-integrator
description: Playtime facts for the integrator session - the rolling post-merge gate on main (quick tier, full tier, baselines), where logs go, the Release-hidden and Android checks, how to read the test queue, what never to touch, and how reports to the coordinator look. Use with the global `integrator` skill (load it first) when the founder says "you are the integrator" on Playtime. Not for merging features in sessions' place and not for the coordinator's job (playtime-coordinator).
---

# Playtime integrator

The Playtime facts for the integrator. The role, merge train and reporting are in the global `integrator` skill; load it first.
Playtime does not do snapshot releases from here: owners fast-forward `main` themselves and you run a **rolling post-merge
gate** on the tips the coordinator gives you. No tag, release, store upload, deploy or push of yours without the founder's
yes relayed through the coordinator. You do not talk to the other sessions: you report to the coordinator.

## Where you work

- Your own integration worktree (`~/git/playtime-integration*`), detached at the tip under test. Never use `~/git/playtime`
  (shared, dirty) or `~/git/playtime-install` (phone installs only). Notes and logs in `~/integrator-notes/pt-<chain>-<tip>/`
  (pkg.log, ui-lint.log, strings.log, android-release.log, lint-summary.txt, progress.txt).
- Machine care: `nice -n 10`, one build at a time, everything heavy through `scripts/heavy.sh` (`--bg`, 3 slots); read
  `heavy-slots/results/queue.log` for ADMIT/WAIT before blaming a test. Stop and tell the coordinator if free disk passes
  below 15 GB; erase your own shut-down simulators first. Your simulators are named for you; never delete someone else's.
- No windows on the founder's screen: quiet test modes only.

## Quick tier (every main tip, aim <= 15 min plus queue)

1. Package tests for the packages touched (Swift Testing, by suite name), counts and times quoted from the log
   ("Test run with N tests in M suites passed"), not "green".
2. `scripts/strings-check.py`, `scripts/ui-lint.sh` for iOS and Android (exit 0).
3. Release-hidden check: a Release build must hide the studio games, Palace and unfinished new games, and show the Online card;
   Debug shows the studio games by default.
4. Android `assembleRelease` (JDK 21; never print or copy `keystore.properties`) on alternate tips.
5. Check that tests of new features actually ran (names present in the log), not skipped.

## Full tier (on a chosen tip, not every tip)

- Debug build, then the full UI run **by test name** against the baseline 75 pass / 14 skip / 1 fail; any change from the baseline
  is reported by name. Sweeps on iPhone SE, iPad and Pro Max (ScreenSweepTests), two-phone pair tests, SE end cards, RTL/Arabic pass.
- One chain (U = UI, P = pairs) at a time; report one message per chain.

## Reporting to the coordinator

One message per chain: the tip (commit, never a branch), what ran by name with counts and times, what failed and whether it is
new against the baseline, the logs' path, and what you did not verify. A red result: reproduce once, then name the owner and
the first failing line. Never fix someone else's code. The founder's hands-on testing is never a gate.
