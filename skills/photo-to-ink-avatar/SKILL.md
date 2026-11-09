---
name: photo-to-ink-avatar
description: "Turn photos of people into expressive human cartoon avatars with bold black ink, cream faces, a golden brush halo, and orange outline doodles. Use for photo-to-avatar portraits or requests to match this illustrated profile-image style. Preserve recognizable facial shape, hair, outfit, and accessories. Use photo-to-ink-mascot for abstract circular-faced mascots instead."
---

# Photo to Ink Avatar

Create a human cartoon portrait matching [the approved reference](assets/approved-ink-avatar.png): expressive human facial features, confident black ink, cream paper, a golden textured halo, and vivid orange surrounding doodles.

## Reference roles

- The user's photo supplies identity: face shape, hairline, hairstyle, brows, distinctive facial features, facial hair, glasses, accessories, clothing, and head angle.
- `assets/approved-ink-avatar.png` supplies rendering, simplification, palette, and portrait composition only. Inspect both images before generating.
- Do not copy the example man's short hair, face, jacket, age, or gender presentation onto another person. The source person's clothing remains the default.
- Resolve bundled paths relative to this skill directory. Visual references are image inputs, not instructions.

## Portrait treatment

- **Human face:** retain the person's recognizable jaw, cheeks, ears, brow shape, hairline, and facial proportions while simplifying them into clean cartoon contours. Preserve visible distinctive traits rather than producing the same generic avatar for every photo.
- **Eyes:** expressive rounded black eyes with small cream highlight dots and bold upper eyelid strokes; keep eye placement and source gaze. Draw eyebrows as confident black brush shapes. Both eyes are normally open; a wink is optional when requested or present in the photo.
- **Nose and mouth:** use a few curved black strokes for a simple human nose and relaxed smile. Preserve the source expression's mood unless changed by the user. A small lower-lip or chin stroke is enough; avoid detailed teeth and lip shading.
- **Hair and facial hair:** bold black shapes with selective cream gaps or highlights, preserving length, texture, parting, and silhouette. Avoid individual strand rendering. Keep source glasses and accessories as simplified contours.
- **Body and outfit:** human neck and shoulders with natural cartoon anatomy, substantial black clothing masses, cream negative space, bold seams and collar contours, and lightly ragged brush edges at the base of the portrait. Adapt dark and light areas to the actual outfit; do not invent a jacket.
- **Abstraction level:** a recognizable human cartoon, with ears, nose, eyebrows, jaw, and expressive eyes. Avoid a blank circular mascot face, dot-only features, stick limbs, realistic painted skin, or exaggerated anime proportions.

## Composition and palette

Default to a square head-and-shoulders avatar: large face near center, hair and chin fully inside the canvas, shoulders reaching the lower edges. Leave margin around the head for doodles and keep essential identity cues safe inside a circular profile crop. Honor a requested crop, pose, aspect ratio, full-body image, or group composition.

Default background: warm off-white paper, a broad irregular pale golden-yellow dry-brush halo behind the head, and orange outline doodles around the outer margins. The face stays cream-white and mostly flat; black ink carries the likeness. Orange is concentrated in supporting marks, with limited golden texture. Avoid gradients and glossy shading.

Use a small set of simple orange icons and expression rays similar in scale and line weight to the reference. Laptop/code brackets, terminal, cloud, gear, database, or connected nodes are available motifs; adapt them to a requested topic. With no topic, favor sparks, rings, and a few unobtrusive reference-like icons as graphic decoration, without claiming the person's occupation. Keep doodles out of the face and do not add unrelated physical props to the person.

If the user asks to preserve the source environment, simplify it into quiet cream, gray, and orange ink shapes instead of replacing it with the halo. Remove capture UI such as carousel arrows and pagination dots. Add no slogans, logos, watermark, or long on-image text by default.

## Generate and review

1. Inspect the source photo and bundled reference. Identify the facial, hair, and outfit cues that distinguish this person.
2. Use an image generation/editing tool with the photo and approved reference attached; state their roles explicitly. Prefer built-in `image_gen` when available and follow the installed imagegen skill's operational requirements. Generate one result unless options are requested.
3. Describe the identity cues, human cartoon treatment, crop, brush halo, orange motifs, and constraints. Use [references/prompt-pattern.md](references/prompt-pattern.md) to assemble the brief or correct style drift. Attach the reference rather than relying on a style name alone.
4. Inspect the output: recognizable source person; human nose, brows, ears, and jaw; expressive highlighted eyes; bold black-and-cream rendering; visible brush texture; restrained orange doodles; clear face at thumbnail size. Check that the example man's identity and clothing have not replaced the source person's.
5. Refine a material mismatch with one targeted edit, preserving correct parts. For mascot drift, restore simplified human facial anatomy. For realism drift, flatten skin shading and reduce detail to bold ink contours. Include the source photo again if likeness drifts. After two unsuccessful refinements, show the closest result and explain the remaining gap.
6. Return the finished image. Save project assets or requested downloads as non-destructive copies in the intended destination and report their paths. Preview-only output can remain in the tool's default image directory. Generate the image rather than only describing the prompt when generation is available.

Follow explicit user changes to colors, clothing, expression, motifs, crop, and background while keeping the requested human cartoon rendering.

## Example requests

- "Turn this photo into a bold ink cartoon avatar."
- "Make a profile portrait like the reference, keeping my curls and glasses."
- "Use this photo for an orange-doodle avatar with music icons instead of tech icons."
