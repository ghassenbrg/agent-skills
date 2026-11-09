# Example briefs

These examples calibrate length and judgment. The tools named under "Available tools" are examples. In a real brief, list only what you confirmed in the environment.

## 1. Simple request: short brief

**User:** "make a reel explaining docker"

```markdown
# Video brief: Docker in 45 seconds

## Goal
A short vertical reel explaining what Docker is and why developers use it, for people who have heard the word but never really got it. Afterwards they should be able to say: "it packages an app with everything it needs, so it runs the same everywhere."

## Format
Instagram Reels / TikTok / Shorts. 9:16, 1080×1920, 30 fps, 30–50 s, English. One MP4.

## Direction
- Open on the pain everyone knows ("works on my machine") and land the hook in the first 2 seconds.
- Then: a container is the app plus its dependencies, one beat on how it differs from a VM, and a single real `docker run` as the payoff.
- Animated diagrams and kinetic type built in code will beat stock imagery here. Keep the look clean and dev-friendly.
- Confident, friendly voiceover with burned-in captions, since most viewers start with sound off.

## Accuracy
Keep it simple without making it wrong. For example, containers share the host kernel; they are not tiny VMs.

## Available tools
Remotion for the composition.

## Your call
Script wording, scenes, visual style, music.
```

## 2. Voice note as content, re-voiced, another language

**User (speech-to-text):** "ok so I attached my voice note, it's me explaining the brik and the couscous thing, use the content but change the speaker, female voice, and make it in japanese, around one minute, no subtitles"
**Files:** `voice/tunisian-food.m4a`

```markdown
# Video brief: Tunisian food for Japanese viewers

## Goal
A one-minute video introducing Tunisian food to Japanese viewers, built from the content of the user's voice note. It should feel warm and appetizing and leave viewers wanting to try these dishes.

## Format
Vertical 9:16, 1080×1920 (assumed, for social). 50–70 s. Japanese. One MP4.

## Source material
- `voice/tunisian-food.m4a`: the user explaining brik, couscous, and the context around them. Transcribe it first. It is the content source only. Take the dishes, details, anecdotes, and tone, not the recording itself. It's spontaneous speech, so ignore the hesitations, repeats, and false starts.

## Requirements
- Narration in Japanese, read by a female voice (not the user's).
- Keep the meaning and the personal, enthusiastic tone of the voice note. Write a natural Japanese script, not a word-for-word translation.
- About one minute.
- No subtitles: don't caption the narration. Short labels such as dish names are fine.

## Direction
- One beat per dish from the voice note, a quick appetizing hook, and a warm close.
- Show dish names in katakana with the original name underneath (ブリック / brik).
- No footage was provided, so realistic generated food stills with slow camera moves are a good fit.
- A light North African music bed, kept low under the voice.

## Accuracy
Use the facts from the voice note and verify anything you add (ingredients, regional variants, customs). Every dish must look like the real Tunisian version, not generic "Middle Eastern food". Check how the dish names read in Japanese.

## Available tools
Remotion, `codex-imagegen`, ffmpeg. No text-to-speech tool was found on PATH or in the installed video skills. Find one that can produce a natural Japanese female voice, and if none is available, stop and report the options before substituting anything.

## Your call
Which details from the voice note fit in a minute, scene order, visual style, music, and the exact voice within "female, warm, natural".

## Before you deliver
- Each dish is on screen while the narration talks about it.
- Every food image has been checked against what the dish really looks like.
```

Outside the block: *Assumed vertical 9:16 for social. Tell me if it's for YouTube (16:9). No TTS tool is installed here, and production will need one for the Japanese voice.*

## 3. Existing footage: analyze first, then make something better

**User:** "check these videos and understand the topic, then make something better"
**Files:** `raw/` with four screen recordings (about 14 min total) of the user setting up GitHub Actions for their project while talking over it.

```markdown
# Video brief: GitHub Actions setup tutorial

## Goal
Turn four rough screen recordings into one tight tutorial that gets a developer from no CI to a working GitHub Actions pipeline. Viewers should be able to follow along and reproduce it.

## Format
YouTube / internal docs, 16:9, 1920×1080, matching the recordings. As short as the steps allow, probably 3–5 min. English.

## Source material
`raw/01.mov` to `raw/04.mov`. Before planning, watch and transcribe all four, then work out:
- the end goal and the actual sequence of steps that worked
- dead ends, retries, and waiting time to cut
- the terminology and the files, commands, and settings that matter
- the clearest moments of footage for each step
- where the user explains something well, worth keeping as narration

This is raw material for a new video, not clips to join end to end.

## Requirements
- Built from the user's recordings: the real repo, real UI, real commands.
- Better than the raw material: tighter, in a clear order, easy to follow.

## Direction
- Open with the result (a green pipeline run), then rewind to how to get there.
- One chapter per step, with a small title card or progress marker.
- Zoom and crop into the part of the screen that matters, speed up waits, and highlight the line being edited.
- Keep the user's own voice, cleaned and tightened, so it stays their tutorial. Re-record or re-voice only the bits that don't work.
- Finish with a recap of the steps and the final workflow file on screen.

## Accuracy
Commands, YAML, and settings shown must match what actually worked in the recordings. If a step is unclear or seems to be missing from the footage, flag it instead of filling the gap from memory.

## Available tools
ffmpeg, Whisper for transcription, Remotion for titles, overlays, and zooms.

## Your call
Chapter boundaries, pacing, overlay style, music (if any).

## Before you deliver
- Someone can follow the video start to finish and end with a working pipeline.
- Code and text on screen are readable at 1080p.
```

## 4. Scoped change to a previous video

**User:** "same idea as the previous video but improve the opening"

Find the previous render and its saved `video-brief.md`. Keep that brief and change only what the request touches:

```markdown
# Video brief: Docker in 45 seconds (v2: new opening)

## Goal
Same video as v1 (`videos/docker-reel/out/docker-reel.mp4`, brief in `videos/docker-reel/video-brief.md`). Only the opening changes: it should grab attention within the first 2 seconds.

## Source material
- The v1 render and its Remotion project in `videos/docker-reel/`. Watch v1 first and work out why the opening is weak (slow start, too much setup, no visual hook).

## Requirements
- Everything from the v1 brief still applies.
- Change only the first ~5 s and whatever transition it needs into the existing second beat. Leave the rest as it is.

## Direction
Lead with a visual or a line that drops viewers into the problem immediately, rather than introducing the topic.

## Your call
The new hook itself.

## Before you deliver
Total duration still within 30–50 s, and the cut into v1's second beat is seamless.
```

## 5. Handing off to a film-style skill

**User:** "whiteboard style video explaining how our payment retries work, use the design doc"
**Files:** `docs/payment-retries.md`. lemo-opuscar is installed.

Only the sections that differ from the usual pattern are shown:

```markdown
## Format
16:9, 1920×1080, 60–90 s, English. Produced with the lemo-opuscar skill in its Whiteboard Explainer style.

## Requirements
- Whiteboard Explainer style. Keep the style's fixed rules.
- Content comes only from `docs/payment-retries.md`: the retry schedule, backoff, idempotency keys, and when a payment is given up on.

## Voice and audio
Synthetic English narration, calm and clear, using the skill's own TTS. No music. Light sound effects are fine.

## Approval
This brief is approved and answers the skill's intake: the facts come from the doc, the user has no own material, the language is English, and no storyboard review is needed. Follow the skill's process (treatment, look, production, self-check) and ask only about what this brief doesn't cover.
```
