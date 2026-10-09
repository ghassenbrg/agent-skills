# agent-skills

Reusable [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) for Claude Code and other skill-aware coding agents.

## Skills

| Skill | What it does | Requires |
|---|---|---|
| [`codex-imagegen`](skills/codex-imagegen/SKILL.md) | Generates project image assets (heroes, illustrations, sprites, video stills, …) by delegating to Codex's built-in image generation through `codex exec`, then saves and verifies the PNG. | [Codex CLI](https://github.com/openai/codex), logged in |

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
```

Conventions for new skills:
- The folder name matches the `name` in the frontmatter, in kebab-case.
- The `description` says what the skill does, when to use it, and when not to, because it is the only part an agent sees before loading the skill.
- Keep `SKILL.md` short and judgment-focused. Put mechanics in scripts that check their own output.
- Add a row to the table above.
