---
name: playtime-coordinator
description: Coordinate the parallel Claude sessions working on Playtime (the family games app, ~/git/playtime) - its repositories and worktrees, the main vs phone-preview branch model, the merge protocol (D92: only the landing role moves main, make check proof, git hooks and guard ON, rolling post-merge gate), the test queue, how builds are installed silently on the founder's phones, the online relay and ghassen-io-infra, Android parity, number blocks (D and design rules), the single decisions page for the founder, approval scoping, and lessons from past incidents. Use together with the global `coordinator` skill (load it first) whenever the founder asks for a coordinator on Playtime, to line up Playtime merges, installs or deploys, or to register a new Playtime session. Not for the feature work itself (create-playtime-game in the repo).
---

# Playtime coordinator

The Playtime facts for the session coordinating the others. The role, startup, ledger, consent rules, reporting and message
habits are in the global `coordinator` skill: load it first. If it is not installed: you do not implement, you never turn a
relayed yes into a permission, and you verify everything below instead of trusting a report. This file keeps no state; ids,
tips and counts are examples to check live (git, `devicectl`, `ls-remote`).

## The project and where things are

- Playtime: a family games app for iPhone (Swift core, SwiftUI) with an Android port (Swift core via JNI + Kotlin/Compose),
  Mochi the companion, local and online play. Repo `ghassenbrg/playtime`, private, `~/git/playtime`. Only `main` is on the
  remote; no tags unless the founder says so (check `git ls-remote --heads --tags origin`).
- `~/git/playtime` is a shared checkout, usually on someone's feature branch and often dirty: never reset, switch or clean it.
  Lead sessions work in their own worktrees (`~/git/playtime-<name>`); `~/git/playtime-install` is detached and clean and is
  used only to build and install on phones.
- Docs: `docs/STATUS.md`, `docs/DECISIONS.md` (D numbers), design rules (numbered, in the design docs), `docs/ANDROID-PARITY.md`,
  `docs/online-host.md`, `docs/ONLINE-MATCHMAKING.md`, `docs/ONLINE-SWITCHES.md` (when it exists), the repo skill
  `.claude/skills/create-playtime-game`. Online host is one setting: `Config/Host.xcconfig` PLAYTIME_HOST (`playtime.ghassen.io`).
- Infra for the relay is a different repository, `~/git/ghassen-io-infra` (k3s + Traefik, GitHub Actions "Playtime Relay Deploy").
  It has its own session. Nothing in Playtime sessions touches it.
- Your ledger: `~/coordinator-notes/playtime-sidefolk.md` (keep appending). The founder's single page of open decisions is
  an Artifact (one page, one list, pictures embedded); stamp it with the real `date`, remove what he answered.

## Two branch models: main and phone-preview

- `main` = verified and stable work only. **Since D92 (2026-11-15) only the landing role moves main** (a strong-model lead or
  the founder): rebase onto current main, `make check` on that exact tree (writes a proof), then push (ff-only, only main). Other
  agents commit on their own branch, never push, send MERGE-READY with the proof. `scripts/land.sh` does not exist yet: by hand.
  **Git hooks are ON** (`core.hooksPath` -> `~/git/playtime/scripts/githooks`: commit-msg refuses Co-Authored-By and AI credit
  lines, pre-commit runs the cheap lints, pre-push allows only a fast-forward of main whose exact tree has a passing proof).
  `~/git/playtime` must stay checked out on `main` and clean: never switch it (the hooks follow its files). The **repo guard**
  (`.claude/settings.json`, `.codex/hooks.json` -> `scripts/agent-guard.sh`) blocks force/tag pushes, `--no-verify`, `run.sh -d`,
  device launch/terminate, simulator freezing, writes to `docs/approved` and `sandbox/`, keystore/infra names, for sessions
  started in a Playtime folder (not for sessions started from the sidefolk folder). No force push, no tags.
- `phone-preview` = the disposable branch for the founder's phone: everything that builds, finished or not, merged in a fixed
  order from current `main`; rebuilt from scratch whenever it gets messy and after every new ready branch; never pushed.
  **Every phone install comes from it, never from plain `main`** (the founder: finished work on other branches never reached
  his phone). Each install is reported with branches IN (tips), OUT (reason), the build number, and what to try first.

## Merge protocol and the rolling gate

- You verify every announced landing: `git fetch`, tip and tree, `merge-base --is-ancestor` from the previous main, the file
  list (code dirs touched?), trailer count 0, origin/main equal; run the quick scripts yourself in a temp worktree when scripts
  changed. A landing claims `make check` on its tree: ask for it, never run the 20-minute check yourself unless asked. Then tell
  the integrator the new tip (commit, never a branch name).
- The integrator runs the rolling post-merge gate (see `playtime-integrator`): a quick tier on main tips and a full tier on
  alternate ones. A red result goes to the owner of the tip; it blocks nothing else unless a fix is promised.
- Owners test their own branch first, name the tests (not "green"), and say what they did not verify.
- Merge-ready lists carry "Not verified" and "Founder's hands-on check" lines; the founder's own testing never blocks a merge.

## Machine and the test queue

- One shared Mac. All heavy runs (xcodebuild test, UI tests, simulators) go through `scripts/heavy.sh` (`--bg`, 3 slots, Tier 1 first).
  Admission looks at free memory (>=25%), swap not growing, disk >=10 GB, CPU idle. Jobs already waiting keep the script they were
  queued with: resubmit after the script changes. Never wait on the Mac: code and write while tests wait.
- Disk watch: alert under 12 GB free, critical under 8 GB; erase shut-down simulators first, then ask. Builds/tests `nice -n 10`.
- Debug apps and tests must not put windows or clicks on the founder's screen unless the coordinator says he is away.

## Phones and installs

- Phones: the founder's iPhone 15 Pro Max (its UDID is in scripts/install-preview.conf) and Kana's iPhone 16e
  (UDID in scripts/install-preview.conf, often unavailable until unlocked on the same Wi-Fi). Check with `xcrun devicectl list devices`.
- **Installs are the coordinator role's only** (D92) and go through `scripts/install-preview.sh` in `~/git/playtime-install`
  (never `run.sh -d`). Order: merge current `main` into `phone-preview` there (disposable, never pushed), `make smoke`
  (`PLAYTIME_HEAVY_DIR=<heavy-slots>`, ~5 min, writes `build/proof/smoke-<tree>.json`), `install-preview.sh --dry-run --tip <commit>
  [iphone|ipad|kana]`, then the real run. It always passes `--no-launch`, refuses a dirty tree or missing proof; the iPhone
  installs over an open app (his word); **2026-11-15 18:05 the founder said "Even Kana's phone and iPad can install if they are
  open. It's fine."**, so installing over an open Playtime is allowed on all three once `scripts/install-preview.conf` says
  `open-ok` for them (until that lands the script still waits: `--wait N`); Kana's still needs `--allow-refused` AND the
  founder's word for each install. Device ids live only in `scripts/install-preview.conf`.
  Verify with `devicectl device info apps` and say "installed silently, not opened". Same app code = no need to reinstall.
- **Launch smoke before every install, crash logs after.** Run the Debug build on a simulator ~10 s and check for a crash log
  first. When the founder says it does not open: `xcrun devicectl device info files --device <UDID> --domain-type
  systemCrashLogs`, copy the newest `Playtime-*.ips` with `device copy from --domain-type systemCrashLogs --source <name>`,
  read the faulting thread (JSON after the first line). 2026-11-13: builds 329-335 trapped at launch in `GameTable.drivers`
  (`Dictionary(uniqueKeysWithValues:)` with duplicate keys after a hand-joined merge); main and build 252 were fine.
- **When the phone "disappears" for Xcode** (devicectl hangs or says "available (paired)", `xcrun xctrace list devices` shows only
  the Mac, xcodebuild says "Unable to find a device matching the provided destination specifier" or "Timed out waiting for
  all destinations", nothing changed on the phone): the Mac's CoreDevice helpers are wedged after a load storm (they had run
  for 2 days). They are user processes: `kill` CoreDeviceService, the RemotePairing XPC service and the two CoreDevice
  private apps (see `ps -axo user,pid,etime,comm | grep -E "CoreDeviceService|RemotePairing|CoreDevice.framework"`); launchd
  restarts them on demand; the phone then shows up in `xctrace` (as Offline until it is ready) and the install goes through.
  Try this BEFORE asking the founder to replug or restart anything. A pasted "DeviceKit 4002 Live device view" error is the
  Xcode/Simulator view of a simulator (check the DeviceIdentifier with `xcrun simctl list devices | grep <id>`), not the phone.
  Run the install as a retry loop (`run.sh` every minute) so it lands when the device returns.
- A lower build number than the phone's installs fine on a development phone ("Its games stay"). Debug builds show the studio
  games by default; Release hides the studio games, Palace and the unfinished new games, and shows the Online card.

## Online relay and approvals

- The relay runs at `https://playtime.ghassen.io` (k3s). Relay code merges to main like any code; **a deploy, an infra change,
  a tag, a release, TestFlight/store upload, Stage 3 public matchmaking being switched on, and Apple/Google account steps each
  need the founder's explicit yes** (relayed in his words). A coordinator's relay of his yes is not a permission the session
  can borrow for another action. Production switches for the online modes are documented in `docs/ONLINE-SWITCHES.md`.
- Measured, not estimated: highest 377 concurrent sockets in the load test; 2,000 / 10,000 / 100,000 are estimates. Traefik runs
  `externalTrafficPolicy: Local` so the relay sees real client addresses.
- Android parity is a standing rule: screen for screen, no accepted difference. The Android lead owns `docs/ANDROID-PARITY.md`;
  every iOS UI change that ships needs its Android note. JDK 21; release APKs live in `~/.android-playtime`; never print or copy
  `keystore.properties`.

## Numbers and the founder's decisions

- Decisions (D) and design rules (e.g. 100 Home, 102 approved design is the minimum, 103 RoomKit, 106 a pinned action never
  covers content, 107 race review) are given out in blocks by you; check the next free number against main and all branches
  before handing one out. Write each founder decision with his exact words in the ledger.
- Approved means the minimum: an approved mockup/reference is the lowest acceptable quality (3D, texture, perspective); "close"
  is not done. A new attempt after a rejection is a new idea, not the old motif again.
- Ask the founder little: decide the rest with the team, put the few real calls on his one page with a recommendation, and keep
  summaries short with percentages when he asks for status. Findings from his testing become rules audited across the whole app.
- Allowance: the weekly limit may stop sessions; resume them when he says it has reset.

## Away mode on Playtime

Follow the global coordinator's "Away mode". Playtime specifics: the founder says it in his own words ("keep working by
yourself, never block on me, decide with your team"); it applies whenever he can't watch (asleep, at the office while the Mac
works at home). Decisions made for him get a D number or a design rule (check the next free ones on every branch first) and
go on the one decisions page under "decided while you were away". Still his alone: relay deploys and any
ghassen-io-infra change, releases and tags, store/TestFlight builds, Apple/Google accounts and credentials, force pushes,
and changing an approved screen below its approved image (rule 102). Phones: build from `phone-preview` with the scan and
launch smoke, install silently with `scripts/run.sh --no-launch`, the founder's iPhone may be locked or off Wi-Fi at night (Xcode then
can't see it): leave a retry loop running (every minute, up to 40 minutes, repeated), and read the build from the phone.
Kana's phone only when idle. Morning: one page with the return summary, installs (build numbers, IN/OUT, try-first), the
decisions made, what waits for his yes (relay deploy question first) and the machine notes.

## Hazards seen on this project

- Background wait-loops pile up: 2026-11-15 the founder noticed 96 orphan `until [ -f X.done ]; do sleep 20; done` shell loops (up to 4
  days old, waiting on result files that never came) from the main Playtime session. Rule: every wait has a timeout
  (`for i in $(seq 1 N)`), never `while pgrep -f <pattern>` (it matches its own command line and never ends), prefer ONE background command with a completion notice, never poll; before wrap-up list and `TaskStop`
  your background tasks; the coordinator checks `pgrep -x sleep` after big batches.
- A command meant for a worktree run in the shared checkout wiped uncommitted edits once: `git -C <absolute path>`, check
  `rev-parse --show-toplevel` first, never reset from a `cd`.
- A swap-size cap in the queue blocked all jobs for 30 minutes while the machine was idle: read the queue log (`ADMIT/WAIT`).
- An install while the founder had the app open closed it. Check processes first.
- A test that depends on a random deal flaked once; fix the test or the seed, do not hide it.
- I installed plain `main` when the founder wanted the phone branch: always use `phone-preview`.
- Wrong clock times in the ledger: always run `date` before stamping.

## Skill upkeep (the founder: sessions always update the skills)

- Before you say done at any milestone, night or handover, update the skill that owns the lesson: this one, `playtime-integrator`,
  the global `coordinator`/`integrator`, and for game work the repo's `create-playtime-game` (SKILL.md + LESSONS.md, landed through
  the landing role). Write rules, hazards and numbers that cost time, tokens or a founder correction (date + incident, 1-2 lines);
  fix or delete stale lines instead of only adding. Commit global skills locally in `~/git/agent-skills` (no trailers); push only on
  the founder's "push skills".
- Every brief you send ends with: "Before you finish, update your skill with what you learned and tell me in one line what you
  added." Ask for that line in each completion report; log it in the ledger.
- Last updated 2026-11-15: D92 rails (landing role, hooks, guard, install-preview); installs over an open app allowed on all three devices; numbers: D97 taken, rules to 139.
