---
name: playtime-coordinator
description: Coordinate the parallel Claude sessions working on Playtime (the family games app, ~/git/playtime) - its repositories and worktrees, the main vs phone-preview branch model, the merge protocol (owners ff-merge to main, rolling post-merge gate), the test queue, how builds are installed silently on the founder's phones, the online relay and ghassen-io-infra, Android parity, number blocks (D and design rules), the single decisions page for the founder, approval scoping, and lessons from past incidents. Use together with the global `coordinator` skill (load it first) whenever the founder asks for a coordinator on Playtime, to line up Playtime merges, installs or deploys, or to register a new Playtime session. Not for the feature work itself (create-playtime-game in the repo).
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

- `main` = verified and stable work only. Owners merge their own work with a fast-forward (`git fetch . <tip>:main`, no
  checkout switch) and `git push origin main` (ff-only, only main) after a secret scan and a trailer scan. No force push, no tags.
- `phone-preview` = the disposable branch for the founder's phone: everything that builds, finished or not, merged in a fixed
  order from current `main`; rebuilt from scratch whenever it gets messy and after every new ready branch; never pushed.
  **Every phone install comes from it, never from plain `main`** (the founder: finished work on other branches never reached
  his phone). Each install is reported with branches IN (tips), OUT (reason), the build number, and what to try first.

## Merge protocol and the rolling gate

- You verify every announced merge: `git reflog` for how main moved, `git ls-remote --heads --tags origin`, tree hashes, trailer
  counts (no Co-Authored-By anywhere), a scan of the range for key file names and secret patterns. Then tell the integrator the
  new tip (commit, never a branch name).
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
- Install only from `~/git/playtime-install` with `./scripts/run.sh -d <UDID> --debug --no-launch`. **Silent**: never launch,
  relaunch or terminate; never install over an open app (check `devicectl device info processes` first; wait up to 30 minutes
  and tell the founder). Verify the build with `devicectl device info apps` and say "installed silently, not opened".
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

## Hazards seen on this project

- A command meant for a worktree run in the shared checkout wiped uncommitted edits once: `git -C <absolute path>`, check
  `rev-parse --show-toplevel` first, never reset from a `cd`.
- A swap-size cap in the queue blocked all jobs for 30 minutes while the machine was idle: read the queue log (`ADMIT/WAIT`).
- An install while the founder had the app open closed it. Check processes first.
- A test that depends on a random deal flaked once; fix the test or the seed, do not hide it.
- I installed plain `main` when the founder wanted the phone branch: always use `phone-preview`.
- Wrong clock times in the ledger: always run `date` before stamping.
