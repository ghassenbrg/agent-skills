# agent-skills

Reusable [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) for Claude Code and other skill-aware coding agents.

## Skills

| Skill | What it does | Requires |
|---|---|---|
| [`coordinator`](skills/coordinator/SKILL.md) | Coordinates many parallel Claude sessions on one project: registers them, assigns file ownership and number blocks, catches overlaps, sequences releases one at a time, verifies claims against git and CI, and relays your decisions in your words. It doesn't implement. | The Claude desktop app's session tools |
| [`integrator`](skills/integrator/SKILL.md) | The other half of the coordinator: builds one integration branch, merges the branches the coordinator reports ready (lowest conflict first), resolves docs and generated-file conflicts but never other people's code, runs one suite and release build on the final commit, and pushes and releases only on the coordinator's explicit go. It doesn't talk to the other sessions. | The Claude desktop app's session tools |
| [`codex-imagegen`](skills/codex-imagegen/SKILL.md) | Generates project image assets (heroes, illustrations, sprites, video stills, …) by delegating to Codex's built-in image generation through `codex exec`, then saves and verifies the PNG. | [Codex CLI](https://github.com/openai/codex), logged in |
| [`codex-worker`](skills/codex-worker/SKILL.md) | Hands small, well-scoped coding tasks from Claude to Codex in a sandboxed worktree, inside a 5-hour and weekly usage budget (reads Codex's live usage, stops at a limit), and has the lead read the diff, run the gates and review before anything moves on. | [Codex CLI](https://github.com/openai/codex), logged in; `python3` |
| [`video-director`](skills/video-director/SKILL.md) | Turns a rough video idea (casual or speech-to-text instructions, voice notes, footage, screenshots, sites, previous versions) into a production brief, revises it with you, and starts production only after you approve. | Nothing; production uses whatever video tools are installed (e.g. Remotion, ffmpeg, `codex-imagegen`) |
| [`orange-ink-editorial`](skills/orange-ink-editorial/SKILL.md) | Creates warm cream, orange, and black brush-and-doodle editorial images using bundled mascot, avatar, and layout references. Separate from the Mr. Snib brand style. | An image generation or editing tool |
| [`photo-to-ink-mascot`](skills/photo-to-ink-mascot/SKILL.md) | Turns photos into abstract rounded brush mascots, preserving hair, outfits, and poses with a bundled approved cream, black, and orange reference. | An image generation or editing tool |
| [`photo-to-ink-avatar`](skills/photo-to-ink-avatar/SKILL.md) | Turns photos into expressive human cartoon avatars with bold black ink, a golden brush halo, and orange outline doodles, using a bundled approved reference. | An image generation or editing tool |

## Install

With the [skills CLI](https://skills.sh/):

```bash
npx skills add ghassenbrg/agent-skills
```

Or, from a clone of this repo, link a single skill into Claude Code manually:

```bash
mkdir -p ~/.claude/skills && ln -s "$PWD/skills/codex-imagegen" ~/.claude/skills/codex-imagegen
```

Once installed, the agent picks up a skill automatically when a task matches its description. You can also ask for it by name.

## Layout

```
skills/
  <skill-name>/
    SKILL.md        # frontmatter (name, description) + instructions
    scripts/        # optional helper scripts the instructions call
    references/     # optional docs the instructions link to, loaded only when needed
```

Conventions for new skills:
- The folder name matches the `name` in the frontmatter, in kebab-case.
- The `description` says what the skill does, when to use it, and when not to, because it is the only part an agent sees before loading the skill.
- Keep `SKILL.md` short and judgment-focused. Put mechanics in scripts that check their own output.
- Add a row to the table above.
