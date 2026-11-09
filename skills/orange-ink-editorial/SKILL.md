---
name: orange-ink-editorial
description: "Generate or edit images in the established orange ink editorial visual language: warm hand-drawn editorial illustration, black/orange/cream palette, expressive brush linework, playful technical/exploration doodles, and consistent recurring characters. Use for orange ink editorial social posts, personal tech-brand avatars, LinkedIn covers, thumbnails, profile images, explainer graphics, and related brand visuals."
---

# Orange Ink Editorial Style

A reusable warm brush-and-doodle editorial treatment. This imported bundle is separate from the Mr. Snib brand style. Historical lettering in reference images is not a brand instruction; use only the identity and wording requested by the user.

Use this skill whenever the user asks to create, redesign, or edit an image so it belongs to the orange ink editorial style.

The goal is not to copy one composition. The goal is to preserve a recognizable **visual language** while adapting subject, layout, platform, and message.

## 1. Start with the correct identity

Before generating, determine which subject is being depicted:

- **Doodle mascot**: use `assets/mascot-reference.png` as the primary identity reference.
- **Personal human avatar**: use `assets/personal-avatar.png` as the primary identity/outfit reference.
- **LinkedIn/personal brand layout**: use `assets/linkedin-banner.png` as a composition/style reference.
- **Social launch / editorial scene**: use `assets/editorial-scene-reference.png` as a composition/style reference.

Do not merge the human avatar and Doodle mascot unless the user explicitly asks for both in the same image.

When the user provides a new photo or character reference, treat it as the **identity reference** and keep this skill only as the **style reference**.

## 2. Style lock — preserve these traits

Every image should feel related even when the subject changes.

### Core palette
- warm cream / off-white base
- deep charcoal or black linework
- vivid orange as the primary accent
- soft golden-yellow used sparingly for glow, highlight, or background energy
- optional muted gray/blue only when the subject requires it

Avoid rainbow palettes unless the user explicitly requests one.

### Line and rendering language
- hand-drawn brush/marker look
- thick, slightly organic black outlines
- simple confident shapes
- visible dry-brush or painted texture in highlights and accents
- mostly 2D illustrated rendering
- light dimensional shading is acceptable, but never turn the character into glossy generic 3D
- avoid anime styling, generic vector-corporate art, hyperrealism, or slick cyberpunk aesthetics

### Decorative vocabulary
Use only a few elements per image, chosen to support the topic:
- orange motion rays
- stars / spark marks
- question marks
- arrows / dotted paths
- lightbulb / idea marks
- hand-drawn boxes, circles, underlines, or brush swashes
- simple diagram arrows

For technical imagery, prefer simple hand-drawn versions of:
- code brackets / terminal window
- cloud
- database cylinder
- server stack
- API nodes / connected dots
- gear
- network graph
- AI chip
- laptop

Decorations should clarify the idea, not fill empty space.

## 3. Character consistency rules

### Doodle mascot
Preserve:
- round white face with thick black circular outline
- simple black brush-line body
- friendly open mouth with orange interior/tongue accent
- minimal eyes; expressive wink is a recurring default
- rounded hands and simple limbs
- energetic, curious, welcoming poses

Do not add complex clothing by default. Add a role-specific accessory only if the scene needs it.

### Personal human avatar
Preserve the appearance and outfit language from `assets/personal-avatar.png`:
- black-and-white illustrated face
- short dark hair
- clean confident expression
- black open-collar jacket over a light shirt
- thick hand-drawn ink contours
- no hoodie unless explicitly requested
- keep facial proportions stable across generations

For LinkedIn, prefer composed, confident poses rather than exaggerated mascot poses. Good defaults: arms crossed, relaxed three-quarter stance, one hand in pocket, holding a laptop/notebook, or subtle pointing/presenting gesture.

## 4. Composition philosophy

The style should feel **simple first, expressive second**.

Prioritize in this order:
1. subject / identity
2. main message
3. readable composition
4. a few relevant environmental elements
5. decorative doodles

Do not let props, labels, or icons compete with the face or headline.

Use generous negative space. If the design starts feeling like an infographic, remove 30–50% of the supporting elements.

## 5. Text in images

Keep on-image text short and purposeful.

- Prefer one headline and at most one supporting line.
- Use hand-drawn, brush-like lettering when possible.
- Use black for most text and orange for one emphasized word/phrase.
- Do not generate long paragraphs inside an image.
- For professional covers, keep the text region away from platform UI/profile-picture overlap areas.

If exact spelling is important, verify every word after generation and regenerate/edit any incorrect text before finalizing.

## 6. Prompt construction workflow

Build the image prompt in this order:

1. **Use case and canvas** — e.g. LinkedIn cover, Instagram post, profile avatar, YouTube thumbnail.
2. **Identity reference** — specify which character/person must be preserved.
3. **Scene or concept** — what the subject is doing and where.
4. **Style lock** — palette, brush linework, hand-drawn 2D editorial feel.
5. **Topic-specific elements** — only the small set that serves the request.
6. **Composition** — hierarchy, empty space, text placement, platform crop safety.
7. **Anti-drift constraints** — explicitly reject generic anime, glossy 3D, corporate vector style, excessive clutter, and identity changes.

See `references/prompt-patterns.md` for reusable prompt blocks.

## 7. Platform presets

Follow `references/platform-presets.md` for the target surface.

Default choices when the user does not specify:
- Instagram feed illustration: 4:5
- profile image/avatar: 1:1
- story/reel cover: 9:16
- LinkedIn personal cover: wide 4:1 composition
- presentation/website hero: 16:9

## 8. Editing existing images

When editing an existing image:
- preserve everything the user did not ask to change
- state the edit target precisely in the generation prompt
- use the original image as a reference whenever possible
- do not redesign the subject when the request is just a text/color/background change

## 9. Quality gate

Before finalizing, inspect the result against all of these:

- Does the subject still look like the intended character/person?
- Is the orange/black/cream brand language obvious without overwhelming the image?
- Does the brush/hand-drawn quality remain visible?
- Is the image simple enough to understand immediately?
- Are technical/science/history elements relevant rather than decorative noise?
- Is text spelled correctly and readable?
- Does the composition survive the platform crop?
- Would this image look related to the reference assets even without a logo?

If two or more checks fail, iterate before presenting the image.

## 10. Output behavior

When the user asks for an image, generate the image rather than only describing it.

When helpful, create 2–4 clearly distinct directions only if the user asks for options. Otherwise choose the strongest single direction.

For a recurring series, keep the visual system stable but vary scene, pose, props, and composition enough that posts do not look templated.
