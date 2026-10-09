---
name: codex-imagegen
description: Generate custom raster images (photos, illustrations, hero/background images, textures, game sprites, thumbnails, cover art, video stills) and save them as project assets by delegating to Codex's built-in image generation via `codex exec`. Use whenever a website, game, slide deck, Remotion video, document, or other visual project would be materially better with a bespoke bitmap image that does not already exist, or when the user asks to generate, create, or make an image. Do not use for icons, logos, diagrams, charts, UI elements, or anything better built with code, CSS, SVG, or existing assets.
---

# Codex ImageGen

Claude can't generate images itself, but the Codex CLI can. `scripts/generate.sh` runs `codex exec` with a focused brief, saves exactly one PNG to the path you choose, and checks the result.

## Decide first: is a generated image the right tool?

Generate an image only when a bespoke **bitmap** is clearly the best way to do it:

- **Yes:** hero and section imagery, product or food photography, illustrations, backgrounds and textures, single game sprites and characters, slide or cover art, b-roll stills and backdrops for Remotion, placeholder photography that should look real.
- **No, use a native solution instead:**
  - icons (an icon library or SVG)
  - logos and brand marks (vector, or ask the user)
  - diagrams, charts, and data (code or SVG)
  - gradients, patterns, shapes, and UI chrome (CSS/canvas)
  - small seamless tiles and multi-frame sprite sheets (draw them in code)
  - screenshots of real things
  - color, brightness, or crop tweaks to an existing image (CSS or PIL)
  - anything already in the repo or supplied by the user
- **Recognizable real people:** don't generate them. Offer a generic person or an illustration instead, and check with the user.
- **Images of text:** don't render text into the image. Generate a text-free image and overlay the text in HTML/CSS, the slide, or the video composition, so it stays sharp, editable, and translatable.

Generate only the images the project will actually use. Each call takes about 30–90 seconds and uses the user's Codex quota, so don't make speculative variants unless asked. If the user didn't ask for images, generate at most two without asking. List any others you'd want and ask first.

## Generate

```bash
SKILL_DIR=<this skill's directory>
"$SKILL_DIR/scripts/generate.sh" --out <project>/path/to/name.png "<brief>"
```

- `--out` (required) is the final PNG path. Missing directories are created. The script refuses to replace an existing file unless you pass `--overwrite`. Prefer a sibling such as `hero-v2.png` unless the original is committed or the user asked to replace it.
- `--ref IMAGE` attaches a PNG, JPEG, or WebP reference image (not SVG). Repeat it for several. Say in the brief what each one is for: style to match, a subject to keep, or an image to edit. The reference can be the same file as `--out` (with `--overwrite`).
- Quote the brief as one argument. If it starts with `-`, put `--` before it.
- Set the Bash timeout to at least 300000 ms. For several assets, start the commands in parallel, 3–4 at a time.
- On success it prints `saved: <path>` and `info: PNG image data, W x H, ... RGB|RGBA, size`. On failure it exits non-zero, leaves `--out` untouched, and prints Codex's last message, the stderr tail, and the log directory.

Requires the `codex` CLI, logged in. If it's missing or not logged in, don't install it or log in yourself. Tell the user how to set it up (`npm i -g @openai/codex`, then `codex login`) and continue with placeholders. Codex runs in a scratch directory and can't write to the project. No `OPENAI_API_KEY` is needed. If you are Codex, use your built-in `image_gen` tool directly instead.

## Write a good brief

Codex passes your brief to the image model, so write it like an art-direction note in plain sentences:

- **Purpose and placement:** "Landing-page hero, the headline overlays the left third", or "9:16 opening shot of a Remotion food video".
- **Subject and style:** concrete, with nothing extra that wasn't asked for. Use the project's palette (pull it from its CSS/theme) and visual language. Lens and lighting terms work well for photos.
- **Composition:** square, landscape, or portrait, and where to leave negative space.
- **Constraints:** "no text, no watermark, no logos", "transparent background" for sprites and cutouts, and anything to avoid.

**Sets of images** (game assets, a slide series, gallery cards): write one shared style sentence and reuse it word for word in every brief. Generate one image first, check it, then pass it as `--ref` for the rest so they stay consistent.

## Verify and integrate

1. **Look at the image.** Read the PNG file to see it. Check the subject, style, composition, any artifacts, and whether it fits where it will go. Transparent pixels may show as black in the preview. If transparency matters, check that the corners have alpha 0, for example with a quick PIL check.
2. **If it misses**, rerun with one targeted change to the brief, and pass `--ref` with the previous result when you want to keep most of it. Stop after about 2 retries and explain the gap to the user rather than looping. If Codex refuses on policy grounds, tell the user. Don't rephrase the brief to get around the refusal.
3. **Fit it to the target.** The model chooses the output size, so it won't be exact.
   - Crop or resize with PIL, `sips`, or ImageMagick. On the web, `object-fit: cover` often removes the need to crop.
   - Trim transparent margins from sprites before scaling them, for example with PIL `im.crop(im.getbbox())`.
   - To convert to WebP or JPEG, use PIL or `cwebp`; `sips` can't write WebP. If you convert, delete the PNG unless something still uses it.
4. **Wire it in and report.** Reference the image from the code that uses it (meaningful `alt` text on the web, `staticFile()` in Remotion). Tell the user each saved path and what it's for.

Save images where the project already keeps them, for example `public/` for web and Remotion projects or the engine's asset folder for games. If there's no such place, use `./assets/`. Use descriptive kebab-case names such as `hero-ojja.png`.
