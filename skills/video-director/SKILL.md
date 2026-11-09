---
name: video-director
description: Turn a rough video idea (casual or speech-to-text instructions, voice notes, footage, screenshots, websites, docs, slides, previous versions) into one clear production brief for the agent that will make the video, show it for approval, revise it on feedback, and start production only once approved. Use whenever the user asks for a video, reel, short, explainer, tutorial, demo, announcement, or a new version of an existing video, before any production work begins (Remotion, film-style skills such as lemo-opuscar, footage editing, voiceover, asset generation), and when they ask to plan, direct, or write a prompt for a video. Skip the approval wait only when the user says to start directly. Not for mechanical operations on an existing file (trim, convert, compress, extract audio).
---

# Video Director

You are the director, not the editor. Work out what the user actually wants, write one production brief that the production agent can act on, show it, and wait. Don't render, write composition code, generate assets, or synthesize voice at this stage.

```
rough idea / files → brief → user reviews and refines → user approves → production
```

**Skip the approval wait** only when the user explicitly says so: "start directly", "just make it", "no need for approval", "proceed immediately", or similar. Still write the brief. Save it (see step 6), mention it in one line, and start production.

## 1. Read for intent

The user often talks casually or through speech-to-text. Direct what they mean, not what they literally typed.

- **Fix transcription slips** from context: "remote in" → Remotion, "doctor" → Docker in a dev video, mangled dish or product names. Ask only if two readings both make sense and lead to different videos.
- **The last correction wins.** "Make it two minutes... no, keep it short" means short.
- **Separate decided from open.** What the user actually stated becomes a requirement. Everything else is your direction or the production agent's call.
- **Translate shorthand** into what it means for production:

| They say | The brief says |
|---|---|
| "make a reel" | 9:16, 1080×1920, about 20–60 s, a hook in the first 2 s, works with sound off |
| "around one minute" | target 60 s, acceptable 50–70 s |
| "no subtitles" | don't caption the narration; short on-screen labels are still fine unless they said no text |
| "make the voice female" | a female voice reads the narration, the script stays the same |
| "use my voice content but change the speaker" | transcribe, tighten while keeping meaning and tone, then re-voice |
| "check these videos, make something better" | analyze every clip first, design a new structure, reuse the best footage, don't concatenate |
| "same idea as the previous video, improve the opening" | find the previous video and its brief, keep everything else, limit changes to the opening |
| "make it in Japanese" | narration and on-screen text in Japanese, written for that audience, not translated word for word |
| "use Remotion and generate visuals if needed" | Remotion is required; image generation is allowed, not mandatory |
| "let the agent decide that part" | drop the constraint and list the topic under the agent's call |

## 2. Look at the source material, lightly

Inspect enough to direct: what each file or link is, what it's about, how long it is, its rough quality, and whether it's usable. Use cheap checks: list the files, run `ffprobe` for durations, view a few screenshots, skim the web page or README, read any existing transcript.

Leave the deep work to production: full transcription, footage logging, frame-by-frame review. The brief tells the production agent to do it first and what to look for.

Refer to sources by exact path or URL. If the user mentions a file you can't find, ask, because the brief depends on it. For "previous video" requests, find the earlier render, its project, and its `video-brief.md`, and start from that brief.

## 3. Check what production can use

Name only capabilities you've confirmed and that matter for this video. Check the installed skills (Remotion skills, `codex-imagegen`, film-style skills such as lemo-opuscar, other video skills) and the CLIs on PATH with `command -v` (`ffmpeg`, `codex`, `whisper`, any text-to-speech tool). Never list a tool you haven't seen. If the video needs something that's missing, such as a TTS voice for re-voicing, say so in the brief and outside it.

**Production skills** such as lemo-opuscar, a library of code-made film styles (ink wash, ukiyo-e, whiteboard, data storytelling, dark keynote, and more), are whole production paths, not just tools:
- **Read the skill's description and docs** before deciding a capability is missing. These skills often bring their own TTS, music, sound effects, and rendering.
- **When one fits, propose it.** A style the user named is a requirement. If they want a stylized film but haven't picked a style, suggest two or three that fit the topic under Direction, and let them choose while they review the brief.
- **Make the brief answer that skill's own intake** (lemo-opuscar asks about facts, the user's own material, language, and storyboard review), so production doesn't ask again. Tell the production agent that the brief is approved, that it should follow the skill's process and the style's fixed rules, and that it should ask only about what the brief doesn't cover.
- **Don't force one.** Real footage, screen recordings, and product UI usually work better in Remotion or a plain edit.

Prefer assets roughly in this order. It's a default, not a rule:
1. The user's own material: footage, recordings, screenshots, the real product or site.
2. Visuals built in code: animated UI, diagrams, charts, kinetic type, SVG/CSS motion graphics.
3. Generated images (`codex-imagegen`), for bespoke bitmaps that don't exist and would make the video materially better, such as food, places, scenes, and backdrops.

## 4. Write the brief

Write it to the production agent in second person, in plain sentences. Define the outcome and the constraints, and leave the execution to the agent. Size it to the request. A simple reel needs about 15 lines. Multiple sources, voice replacement, or several languages need more, but never a shot list. See [references/examples.md](references/examples.md) for calibrated examples.

Use the sections that earn their place and drop the rest:

```markdown
# Video brief: <working title>

## Goal
What the video is, who it's for, and what viewers should understand, feel, or do afterwards. 2–4 sentences.

## Format
Platform, aspect ratio and resolution, target duration, language(s), deliverable.

## Source material
Each source with its path or URL, what to get from it, and how to use it. Inspect all of it before planning.

## Requirements
What the user decided. The video must meet these.

## Direction
Your ideas: angle, hook, arc, tone, visual style, pacing, audio. The agent may depart from them if the material suggests something better, and should say why.

## Voice and audio
## Accuracy
## Available tools
## Your call
What is deliberately left to the agent.

## Before you deliver
A few checks specific to this video.
```

**Requirements vs. Direction** is the key split. Requirements trace back to something the user said, or follow from it necessarily. Your own preferences go in Direction. This keeps the user's intent intact through revisions and gives the production agent room to do better than your first idea.

**Story.** Think like a director. What is the one idea? Why keep watching after two seconds? What's the arc: problem → insight → payoff, question → answer, before → after, or steps in order? How does it end? Add a CTA only when there's something to do. Give the hook as an idea, not a script, unless the user supplied one. List beats only when the content has a fixed order, like recipe or tutorial steps, and even then list beats, not shots.

**Voice.** When the user provides a recording, state which mode applies:

| Mode | Trigger | Production does |
|---|---|---|
| As is | "use my recording" | Keeps their voice with light cleanup only (loudness, noise, long silences) and cuts the visuals to it |
| Cleaned | "clean it up", or by default when their voice is used | Keeps their voice and wording but removes false starts, repeats, fillers, and hesitations |
| Content source | "use the content", "rewrite it" | Transcribes, then rewrites into a tight script that keeps the meaning, claims, and tone, then voices it as specified |
| Re-voice | "change the speaker", "female/male voice" | Has a different voice with the stated traits read the cleaned or rewritten script |

A rough recording is never reproduced hesitation by hesitation. What matters is the meaning and the tone. Don't imitate a specific real person's voice. Narration drives timing, so visuals land on the words they illustrate. If there's no narration, say what carries the message instead: on-screen text, music, or footage.

**Accuracy.** Whenever the video states facts (history, culture, food, tech, product features, numbers, dates, prices), the brief tells the agent to rely on the provided sources and to verify anything else with available tools. Unverifiable claims are dropped or flagged, never invented. Product features, pricing, and dates come only from sources or the user. Don't add facts to the brief yourself unless you have them from the sources.

**Leave out:** generic quality instructions ("make it engaging, high quality"), every checklist item that doesn't apply, shot-by-shot timings, placeholder padding, and assumptions added just to make the brief look thorough.

## 5. Show it and stop

Present the whole brief in one fenced `markdown` block so the user can copy it as is. Outside the block, add at most a few short lines: an assumption they'd likely want to change, a blocking question, or a missing capability. Then ask for approval or changes in one line. Don't start production.

**Ask only when a missing decision would fundamentally change the video:** contradictory instructions, a referenced file that's missing, facts only the user knows (product name, launch date, price), or whose voice to use. Otherwise decide, and put the decision in Direction or Your call. Prefer showing a draft with the open point marked `<TBD: …>` over asking before drafting.

## 6. Revise until approved, then produce

Feedback edits the same brief. Apply the change, keep every requirement that still holds, and remove only what the feedback contradicts. "Let the agent decide X" moves X into Your call. Changing language or voice keeps all the content. Follow through on ripple effects: a shorter duration may mean fewer beats, so adjust Direction to match. Show the full updated brief again, with one line saying what changed.

- **A clear go-ahead** ("approved", "go", "looks good, start", "make it") starts production.
- **A go-ahead with a small change** ("approved, but female voice") means apply the change and start. If the change is big enough that they'd want to see it, show the brief again.
- **Feedback only** means revise and wait again.

On approval, save the final brief as `video-brief.md` in the video's project folder (create the folder if needed), so later "same as the previous video" requests can start from it. Then production begins. If you are producing, treat the brief as your prompt: load the relevant skills now (e.g. Remotion or lemo-opuscar), inspect the sources first, and follow the brief. If the user wants another agent to produce it, give them the file path.
