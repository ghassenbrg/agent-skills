---
name: codex-imagegen
description: Generate custom raster images (photos, illustrations, hero/background images, textures, game sprites, thumbnails, cover art, video stills) and save them as project assets by delegating to Codex's built-in image generation via `codex exec`. Use whenever a website, game, slide deck, Remotion video, document, or other visual project would be materially better with a bespoke bitmap image that does not already exist, or when the user asks to generate, create, or make an image. Do not use for icons, logos, diagrams, charts, UI elements, or anything better built with code, CSS, SVG, or existing assets.
---

# Codex ImageGen

Claude can't generate images itself, but the Codex CLI can. `scripts/generate.sh` runs `codex exec` with a focused brief, has Codex generate exactly one image, then collects that image itself and saves it as a PNG at the path you choose.

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
- Codex runs on `gpt-6-luna` at `xhigh` effort by default. It only relays the brief to the image model, so the cheap model keeps most of the quota for the images themselves. If a Luna result is clearly worse (weak linework, drifts from the references, ignores the brief), regenerate that one with `--sol` (`gpt-6.1-sol`), tell the user what Luna got wrong, and wait for them before switching a whole batch. `--model NAME` or `CODEX_IMAGEGEN_MODEL` picks any other model.
- `--keep-logs` keeps Codex's event log (token usage) and prints its directory. `--effort LEVEL` (or `CODEX_IMAGEGEN_EFFORT`) sets Codex's reasoning effort (default `xhigh`; `high` is close behind; low and medium drift off the brief).
- Codex never saves files. It runs read-only and only calls `image_gen`; Codex stores each generation under `$CODEX_HOME/generated_images/<thread id>/`, and the script copies this run's image from there. That means no shell steps, about 45–70k input tokens per image, and never another parallel job's picture. If it prints `warning: Codex generated N images`, it used the last one; look at it before using it.
- On success it prints `saved: <path> (<model>, <effort>)` and `info: PNG image data, W x H, ... RGB|RGBA, size`. On failure it exits non-zero, leaves `--out` untouched, and prints Codex's last message, the stderr tail, and the log directory.

Requires the `codex` CLI, logged in. If it's missing or not logged in, don't install it or log in yourself. Tell the user how to set it up (`npm i -g @openai/codex`, then `codex login`) and continue with placeholders. Codex runs read-only in a scratch directory and can't write anywhere. No `OPENAI_API_KEY` is needed. If you are Codex, use your built-in `image_gen` tool directly instead.

## Write a good brief

Codex passes your brief to the image model, so write it like an art-direction note in plain sentences:

- **Purpose and placement:** "Landing-page hero, the headline overlays the left third", or "9:16 opening shot of a Remotion food video".
- **Subject and style:** concrete, with nothing extra that wasn't asked for. Use the project's palette (pull it from its CSS/theme) and visual language. Lens and lighting terms work well for photos.
- **Composition:** square, landscape, or portrait, and where to leave negative space.
- **Constraints:** "no text, no watermark, no logos", and anything to avoid. For anything that must be transparent, follow the next section.

**Sets of images** (game assets, a slide series, gallery cards): write one shared style sentence and reuse it word for word in every brief. Generate one image first, check it, then pass it as `--ref` for the rest so they stay consistent.

## Transparent images

Characters, sprites, cutouts and anything placed over a page or a scene must be **generated transparent from the start**. The image model can return real alpha (the script's `info:` line says `RGBA`).

**Never** generate on white, green or any other background and then delete it with rembg, a chroma key, a threshold or similar. It looks cheap: white patches under feet, between legs and around small props, and halos on dark pages. If a result has no alpha or has leftovers, generate it again. Don't repair it.

**Say so in the brief,** in these words or close to them:

> Generate on a genuinely transparent background from the very start: paint no background, no floor, no ground, no contact shadow, no glow and no white or coloured patch anywhere. Every pixel outside the subject is fully transparent, including between and under the feet.

- **Redoing a flawed cutout:** pass it as `--ref`, and say that its leftovers must not be copied. Describe the subject's shape and colours too, or it drifts: say what must stay ("one plain smooth coral colour, no stitching") and pass a finished image from the set as a second `--ref` for surface and lighting only.
- **Leave out small loose marks** (sparks, music notes) unless they matter. They're where leftovers hide.

**Check every transparent image the same way, including ones you didn't generate.** Art already in a project may be an old cutout, so check it before you reuse it.

```bash
python3 "$SKILL_DIR/scripts/check_transparent.py" a.png b.png c.png --sheet /tmp/check.png
```

Then read the sheet. It shows each image on magenta, dark and white, plus its bottom edge enlarged. Transparent corners prove nothing: a patch under the feet touches the subject and the corners stay clear. Previews hide it too, because transparent pixels look black or white. Look at the sheet at a real size, and judge the subject against its reference as well, since a clean edge on the wrong character is still wrong.

- `--clean out.png` clears faint specks far from the subject and trims to it. It doesn't touch the subject's own soft edge, and it's only for specks: a patch attached to the subject means generate again.
- Trim with `--clean`, not plain `im.getbbox()`, because faint dust often makes that box the whole canvas.
- Keep quality when you convert: `cwebp -q 92 -alpha_q 100 -m 6 in.png -o out.webp`. When scaling down, use LANCZOS on RGBA. Keep at least twice the largest size it's shown at.

## Verify and integrate

1. **Look at the image.** Read the PNG file to see it. Check the subject, style, composition, any artifacts, and whether it fits where it will go. Transparent pixels may show as black in the preview. If it should be transparent, run the check in "Transparent images".
2. **If it misses**, rerun with one targeted change to the brief, and pass `--ref` with the previous result when you want to keep most of it. Stop after about 2 retries and explain the gap to the user rather than looping. If Codex refuses on policy grounds, tell the user. Don't rephrase the brief to get around the refusal.
3. **Fit it to the target.** The model chooses the output size, so it won't be exact.
   - Crop or resize with PIL, `sips`, or ImageMagick. On the web, `object-fit: cover` often removes the need to crop.
   - Trim transparent margins from sprites before scaling them, with `check_transparent.py --clean`.
   - To convert to WebP or JPEG, use PIL or `cwebp`; `sips` can't write WebP. If you convert, delete the PNG unless something still uses it.
4. **Wire it in and report.** Reference the image from the code that uses it (meaningful `alt` text on the web, `staticFile()` in Remotion). Tell the user each saved path and what it's for.

Save images where the project already keeps them, for example `public/` for web and Remotion projects or the engine's asset folder for games. If there's no such place, use `./assets/`. Use descriptive kebab-case names such as `hero-ojja.png`.
