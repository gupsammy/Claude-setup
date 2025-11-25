---
name: gemini-imagegen
description: Generate and edit images using the Gemini API (Nano Banana). Use this skill when creating images from text prompts, editing existing images, applying style transfers, generating logos with text, creating stickers, product mockups, or any image generation/manipulation task. Supports text-to-image, image editing, multi-turn refinement, and composition from multiple reference images.
---

# Gemini Image Generation

Generate and edit images using Google's Gemini API. Requires `GEMINI_API_KEY` environment variable.

## Default Output & Logging

When the user doesn't specify a location, save images to:
```
/Users/samarthgupta/Documents/generated images/
```

Every generated image gets a companion `.md` file with the prompt used (e.g., `logo.png` → `logo.md`).

When gathering parameters (aspect ratio, resolution), offer the option to specify a custom output location.

---

## Core Prompting Principle

**Describe scenes narratively, don't list keywords.** Gemini has deep language understanding—write prompts like prose, not tags.

```
❌ "cat, wizard hat, magical, fantasy, 4k, detailed"

✓ "A fluffy orange tabby sits regally on a velvet cushion, wearing an ornate
   purple wizard hat embroidered with silver stars. Soft candlelight illuminates
   the scene from the left. The mood is whimsical yet dignified."
```

### The Formula

```
[Subject + Adjectives] doing [Action] in [Location/Context].
[Composition/Camera]. [Lighting/Atmosphere]. [Style/Media]. [Constraint].
```

Not every prompt needs every element—match detail to intent.

### Prescriptive vs Open Prompting

**Prescriptive** (user has specific vision): Detailed descriptions, exact specifications
**Open** (exploring/want model creativity): General direction, let model decide details

Both are valid. Ask the user's intent if unclear.

---

## Capability Patterns

### Photorealistic Scenes
Think like a photographer: describe lens, light, moment.
- Specify camera (85mm portrait, 24mm wide), aperture (f/1.8 bokeh, f/11 sharp throughout)
- Describe lighting direction and quality (golden hour from camera-left, three-point softbox)
- Include mood and format (serene, vertical portrait)

### Product Photography
- **Isolation**: Clean white backdrop, soft even lighting, e-commerce ready
- **Lifestyle**: Product in use context, natural setting, aspirational but authentic
- **Hero shots**: Cinematic framing, dramatic lighting, space for text overlay

### Logos & Text (Use Pro Model)
- Put text in quotes: `'Morning Brew Coffee Co'`
- Describe typography: "clean bold sans-serif with generous letter-spacing"
- Specify color scheme, shape constraints, design intent
- Iterate with multi-turn chat for refinement

### Stylized Illustration
- Name the style: "kawaii-style sticker", "anime-influenced", "vintage travel poster"
- Describe design language: "bold outlines, flat colors, cel-shading"
- Include format constraints: "white background", "die-cut sticker format"

### Editing Images
- **Acknowledge subject**: "Using the provided image of my cat..."
- **Explicit preservation**: "Keep everything unchanged except..."
- **Realistic integration**: "should look naturally printed on the fabric"

Pattern: Acknowledge → specify change → describe integration → preserve the rest

### Multi-Image Composition (Pro Model)
- State output goal first
- Assign elements: "Take X from first image, Y from second"
- Describe integration requirements (lighting match, realistic shadows)
- Supports up to 14 reference images

### Character Consistency
- Use multi-turn chat session for multiple views
- Reference distinctive features explicitly in follow-ups
- Include "exact same character" or "maintain all design details"
- Save successful designs as reference for future prompts

---

## Invoking Aesthetics Through Naming

Names invoke aesthetics. The model learned associations for film stocks, cameras, studios, artists, and styles. Instead of describing characteristics, reference the name directly.

```
"Portrait at golden hour, shot on Kodak Portra 400"
→ Warm skin tones, pastel highlights, fine grain

"Studio Ghibli forest scene"
→ Lush nature, soft lighting, whimsical atmosphere

"Fashion editorial, Hasselblad medium format"
→ Exceptional detail, shallow DOF, that medium format look
```

This works for photography, animation, illustration, game art, graphic design, fine art—anything with a recognizable visual identity.

**See [STYLE_REFERENCE.md](STYLE_REFERENCE.md) for comprehensive lexicon of film stocks, cameras, studios, artists, and styles.**

---

## Models

| Model | Best For |
|-------|----------|
| `gemini-2.5-flash-image` | Speed, iteration, simple generation (1024px fixed) |
| `gemini-3-pro-image-preview` | Text rendering, complex instructions, high-res (up to 4K), multi-image composition, Google Search grounding |

**Defaults**: Pro model uses 1K resolution, 1:1 aspect. Confirm with user before changing.

### Image Configuration (Pro Only)

**Aspect ratios**: 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9
**Resolutions**: 1K (~1024px), 2K (~2048px), 4K (~4096px)

---

## Advanced Features

### Google Search Grounding (Pro Only)
Enable with `--grounding` flag when real-time data helps:
- Weather visualizations
- Current events infographics
- Real-world data charts

### Multi-Turn Refinement
Use chat for iterative editing instead of perfecting prompts in one shot:
```
→ "Create a logo for Acme Corp"
→ "Make the text bolder"
→ "Add a blue gradient background"
```

### Semantic Masking
No manual masking needed. Describe changes conversationally:
- "Change the sofa to red leather"
- "Replace the background with a sunset beach"
- "Remove the power lines from the sky"

---

## Scripts

```bash
# Generate from prompt
python scripts/generate_image.py "prompt" output.png [--model MODEL] [--aspect RATIO] [--size SIZE] [--grounding]

# Edit existing image
python scripts/edit_image.py input.png "instruction" output.png [--model MODEL] [--aspect RATIO] [--size SIZE]

# Compose multiple images
python scripts/compose_images.py "instruction" output.png img1.png [img2.png ...] [--model MODEL] [--aspect RATIO] [--size SIZE]

# Interactive multi-turn chat
python scripts/multi_turn_chat.py [--model MODEL] [--output-dir DIR]
```

Models: `gemini-2.5-flash-image` (default), `gemini-3-pro-image-preview`

---

## Core API Pattern

```python
from google import genai
from google.genai import types

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=["Your narrative prompt here"],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"])
)

for part in response.parts:
    if part.inline_data:
        # Save image from part.inline_data.data
```

For Pro model with configuration:
```python
config=types.GenerateContentConfig(
    response_modalities=['TEXT', 'IMAGE'],
    image_config=types.ImageConfig(aspectRatio="16:9", imageSize="2K"),
    tools=[{"google_search": {}}]  # Optional grounding
)
```

---

## Quick Checklist

Before generating:
- [ ] Narrative description (not keyword list)?
- [ ] Camera/lighting details for photorealism?
- [ ] Text in quotes, font style described?
- [ ] Right model for task (Pro for text/complex)?
- [ ] Aspect ratio appropriate for use case?
- [ ] User preference: prescriptive or open?
