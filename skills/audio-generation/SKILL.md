---
name: audio-generation
description: >
  Generate speech audio using MLX Audio CLI with Qwen3 TTS models. Use when user says
  "generate audio", "create speech", "text to speech", "design a voice", "clone this voice",
  "make a voiceover", "generate dialogue", "TTS", or any speech synthesis request.
  Supports voice design (custom voice creation), voice cloning (replicating a voice for new text),
  and predefined custom voices.
---

# Audio Generation with MLX Audio

Generate high-quality speech using Qwen3 TTS models on Apple Silicon. Three modes available: Voice Design, Voice Clone, and Custom Voice.

## Prerequisites

Requires `mlx-audio` CLI installed via:
```bash
uv tool install --force "mlx-audio[tts]" --prerelease=allow --python 3.12
```

Models download automatically on first use to `~/.cache/huggingface/hub/`.

---

## The Three Modes

### 1. Voice Design Mode

Create custom voices from natural language descriptions. Use the VoiceDesign model to generate a voice sample that captures specific characteristics.

**Model:** `mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit`

```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit \
  --text "The preview text that matches the voice character..." \
  --instruct "Detailed voice description" \
  --lang_code English \
  --output_path ./voices \
  --file_prefix my_voice \
  --play
```

**Key parameters:**
- `--instruct`: The voice design prompt (see Voice Design Prompting below)
- `--text`: Preview text that demonstrates the voice's range
- `--play`: Play audio immediately after generation

### 2. Voice Clone Mode

Clone a designed (or any reference) voice to generate new dialogue. Uses reference audio + transcript to replicate voice characteristics.

**Model:** `mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit`

```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit \
  --text "New dialogue to speak in the cloned voice..." \
  --ref_audio ./voices/my_voice_000.wav \
  --ref_text "The original text from the reference audio..." \
  --lang_code English \
  --output_path ./output \
  --file_prefix cloned_dialogue \
  --play
```

**Key parameters:**
- `--ref_audio`: Path to reference voice audio file
- `--ref_text`: Transcript of the reference audio (required for best results)

### 3. Custom Voice Mode

Use predefined speaker voices. Useful for quick testing or when specific character voices are needed.

**Model:** `mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit`

```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit \
  --text "Text to speak..." \
  --voice vivian \
  --lang_code English \
  --play
```

**Available voices:** `serena`, `vivian`, `uncle_fu`, `ryan`, `aiden`, `ono_anna`, `sohee`, `eric`, `dylan`

---

## Recommended Workflow

**Design → Clone → Generate**

1. **Design the voice** using VoiceDesign model with a detailed instruct prompt and matching preview text
2. **Save both outputs:**
   - The generated audio file (e.g., `./voices/myvoice_000.wav`) → becomes `--ref_audio`
   - The preview text you used → becomes `--ref_text`
3. **Clone for new dialogue** using the Base model with the designed voice as reference

**Important:** The preview text used during voice design MUST be saved. You need both the audio file AND its transcript for voice cloning. Without the correct `--ref_text`, cloning quality degrades significantly.

This workflow ensures consistent voice characteristics across multiple generations. The designed voice serves as your "voice template" for all subsequent cloning.

---

## Voice Design Prompting

The instruct prompt tells the model how the voice sounds. A well-crafted prompt can be the difference between a generic voice and one that fits your vision.

**The right level of detail depends on your use case.** More descriptive prompts yield more specific voices. But short and simple works for neutral or broadly usable voices.

Simple prompt for a neutral narrator:
```
A calm male narrator with a warm tone.
```

Detailed prompt for a specific character:
```
A lower-pitched, raspy female voice. Gravelly, harsh, icy and emotionless. Flat affect, zero warmth.
```

**Only include what matters for THIS voice.** You don't need to specify every attribute. If age doesn't matter, don't mention it. If pacing should be normal, you can leave it out.

### Attribute Reference

These are terms the model understands. Use them when relevant:

**Age** — Only specify if it matters for the character
- "adolescent", "young adult", "in their 20s", "middle-aged", "woman in her 40s", "elderly", "old man"

**Pitch & Timbre** — The physical quality of the voice
- Pitch: "low-pitched", "high-pitched", "deep"
- Texture: "smooth", "rich", "gravelly", "raspy", "nasally", "breathy", "booming", "resonant", "thin", "warm", "mellow", "harsh"

**Accent** — Use "thick" or "slight" for intensity
- "thick French accent", "slight Southern drawl", "crisp British accent", "soft Irish lilt", "heavy Eastern European accent", "neutral American accent"
- Fantasy: "An elf with a proper British accent, regal and lyrical"

**Emotion & Attitude** — The feeling in the voice
- "energetic", "enthusiastic", "lively", "excited"
- "sad", "melancholic", "emotional"
- "sarcastic", "dry", "cynical", "world-weary"
- "warm", "friendly", "sweet"
- "angry", "intense", "loud", "boisterous"
- "calm", "flat affect", "emotionless", "icy"

**Pacing** — Only specify if not normal pace
- "speaking quickly", "at a fast pace"
- "relaxed and conversational"
- "erratic pacing, with abrupt pauses"
- "staccato delivery"

**Audio Quality** — Usually "studio quality" unless you want an effect
- Clean: "studio quality", "perfect audio quality", "clear fidelity"
- Lo-fi effects: "low-fidelity audio", "poor audio quality", "sounds like a voicemail", "muffled and distant, like on an old tape recorder", "old radio broadcast"

### Example Prompts and Preview Text

These show the range from simple to detailed. The preview text should match the voice character.

**Simple examples:**

| Voice | Instruct Prompt | Preview Text |
|-------|-----------------|--------------|
| **Calm narrator** | A calm male narrator with a warm tone. | "Sometimes the longest roads lead to the most beautiful destinations. Take your time. There's no rush." |
| **Lo-fi voicemail** | A tired man leaving a voicemail. Low-fidelity audio, muffled, sounds like an old answering machine. | "Hey, it's me. Just calling to check in. Call me back when you get a chance." |

**Character examples:**

| Voice | Instruct Prompt | Preview Text |
|-------|-----------------|--------------|
| **Female Sports Commentator** | A high-energy female sports commentator with a thick British accent, passionately delivering play-by-play coverage of a football match in a very quick pace. Her voice is lively, enthusiastic, and fully immersed in the action. | OH MY WORD — WHAT A GOAL! She picks it up just past midfield, dances through TWO defenders like they're not even THERE, and absolutely SMASHES it into the top corner! The goalkeeper had NO CHANCE! |
| **Drill Sergeant** | An army drill sergeant shouting at his team of soldiers. He sounds angry and is speaking at a fast pace. | LISTEN UP, you sorry lot! I didn't come here to babysit — I came to BUILD SOLDIERS! You move when I say move, and you breathe when I say breathe! |
| **Evil Ogre** | A massive evil ogre speaking at a quick pace. He has a silly and resonant tone. | "Your weapons are but toothpicks to me. [laughs] Surrender now and I may grant you a swift end. I've toppled kingdoms and devoured armies." |
| **British Entrepreneur** | Excellent audio quality. A man in his 30s to early 40s with a thick British accent speaking at a natural pace like he's talking to a friend. | [laughs] See, that's the thing. YOU see a company, while I see... [lip smacks] I see a promise, ya know what I mean? [exhales] We don't build just to profit, we build to UPLIFT! |
| **Southern Woman** | An older woman with a thick Southern accent. She is sweet and sarcastic. | "Well sugar, if all we ever do is chase titles and trophies, we're gonna miss the whole darn point. [light chuckle] I'd rather build somethin' that makes folks' lives easier." |
| **Movie Trailer Voice** | Dramatic voice, used to build anticipation in movie trailers, typically associated with action or thrillers. | "In a world on the brink of chaos, one hero will rise. Prepare yourself for a story of epic proportions, coming soon to the big screen." |
| **Angry Pirate** | An angry old pirate, loud and boisterous. | "I've faced storms that would turn your hair white and sea monsters that would make your knees quake. You think you can cross Captain Blackheart and live to tell the tale?" |
| **New Yorker** | Deep, gravelly thick New York accent, tough and world-weary, often cynical. | "I've been walking these streets longer than you can imagine, kid. There's nothing you can say or do that'll surprise me anymore." |
| **Mad Scientist** | A voice of an eccentric scientific genius with rapid, erratic speech patterns that accelerate with excitement. His German-tinged accent becomes more pronounced when agitated. The pitch varies widely from contemplative murmurs to manic exclamations. | "I am doctor Heinrich, revolutionary genius rejected by the narrow-minded scientific establishment! Bah! They called my theories impossible, my methods unethical—but who is laughing now? (maniacal laughter)" |

---

## Writing Preview Text

The preview text acts as a performance script. It sets the tone, pacing, and emotional delivery the voice will match.

### Core Principle

**Preview text must complement the voice description, not contradict it.**

| Voice Description | Bad Preview | Good Preview |
|-------------------|-------------|--------------|
| Calm, reflective younger female | "Hey! I can't STAND what you've done!" | "It's been quiet lately... I've had time to think, and maybe that's what I needed most." |
| Angry drill sergeant | "Please consider improving your performance." | "You've got ten seconds to fall in line or you'll REGRET IT!" |

### Length Sweet Spot

Preview text needs to be long enough to establish character, but short enough to fully generate. The sweet spot is **2-4 sentences (30-50 words)**.

- Too short ("Hello there.") → unstable, abrupt, doesn't capture range
- Too long (100+ words) → hits ~1200 token limit, cuts off mid-sentence
- Just right → enough context for stable expression, completes fully

### Avoid Explicit Slowness Instructions

**WARNING:** Do NOT use pacing instructions like "slow," "deliberate," "unhurried," or "pacing is slow" in the instruct prompt. The model interprets these literally and pads the audio with excessive silence, causing:
- Generation to hit max token limits
- Audio that's mostly dead air
- Text that cuts off mid-sentence

Instead of describing pace, let the punctuation in your preview text control timing (ellipses for pauses, em dashes for breaks).

**Example at the sweet spot:**
```
You know... there's something about evenings like this. The city quiets down,
the lights come on, and everything feels a bit more manageable. Just a moment to breathe.
```

### Using Punctuation for Expression

The way you write text directly controls delivery. Flat sentences produce flat delivery. See the Punctuation Guide table in "Writing TTS Text for Cloned Voices" below for the full reference.

### Examples

**High energy (Sports Commentator):**
```
OH MY WORD — WHAT A GOAL! She picks it up just past midfield, dances through
TWO defenders like they're not even THERE, and absolutely SMASHES it into the
top corner! The goalkeeper had NO CHANCE! That is WORLD-CLASS!
```

**Conversational with emotion (British Entrepreneur):**
```
[laughs] See, that's the thing. YOU see a company, while I see... [lip smacks]
I see a promise, ya know what I mean? [exhales] We don't build just to profit,
we build to, to UPLIFT! If our technology doesn't leave the world kinder,
smarter, and more connected than we found it... [sighs] then what are we even doing here?
```

**Character voice (Evil Ogre):**
```
"Your weapons are but toothpicks to me. [laughs] Surrender now and I may grant
you a swift end. I've toppled kingdoms and devoured armies. What hope do you
have against me?"
```

---

## Writing TTS Text for Cloned Voices

When generating new dialogue with cloned voices, the same principles apply. Your text quality directly affects output quality.

### Match Expressiveness to Voice

If you designed an expressive, dynamic voice, write expressive text. Using flat text with a dynamic voice wastes the voice's potential.

### Punctuation Guide for TTS

| Technique | Effect | Example |
|-----------|--------|---------|
| Ellipses `...` | Pause, hesitation, trailing off | "I thought so... but now I'm not sure..." |
| Em dash `—` | Abrupt break, dramatic pause | "The answer is — and always has been — right here." |
| CAPS | Emphasis, loudness | "That's NOT what I meant!" |
| Multiple punctuation `!!` `??` | Intensity, strong emotion | "Are you serious?? That's amazing!!" |
| `[action]` | Performance direction | "[whispers] Don't tell anyone, but... [normal] it's true." |
| Commas | Brief pauses, natural rhythm | "Well, you know, sometimes things just happen." |
| Short sentences | Punchy, impactful | "Stop. Think. Then act." |

---

## Voice Design Interview

When the user wants to design a voice, gather enough direction to write a good instruct prompt. Don't over-interview—just get what you need.

### What to Ask

**Context:** "What's this voice for? Character, narrator, something else?"

**Direction:** "What's the vibe? Any particular qualities that matter most?" (Let user describe in their own words)

**References:** "Any voices that inspire this? Or voices to avoid?"

**Specifics:** If user mentions something vague like "British accent" or "deep voice," probe once: "What kind of British? Posh, working-class, something else?" But don't exhaustively question every attribute.

### Writing the Instruct Prompt

After gathering direction, write a prompt using vocabulary from the Attribute Reference. Include only what matters for this voice.

**From user description to instruct:**

User says: "A scarred fighter, around 40, cold predator energy, harsh and gravelly"
→ Instruct: `A lower-pitched, raspy female voice. Gravelly, harsh, icy and emotionless. Flat affect, zero warmth.`

User says: "Friendly Southern grandma type"
→ Instruct: `An older woman with a thick Southern accent. Warm, friendly, sweet.`

User says: "Just a normal narrator"
→ Instruct: `A calm male narrator with a warm tone.`

**Avoid in instruct prompts:**
- Backstory ("forged in captivity")
- Metaphors ("voice like grinding stones")
- Abstract qualities ("something dangerous underneath")

**Use in instruct prompts:**
- Concrete audio terms from the Attribute Reference
- Only the attributes that matter for this voice

---

## Pre-Generation Checklist

### For Voice Design
- Instruct prompt uses concrete audio terms (not metaphors or backstory)
- Preview text matches the voice and is 2-4 sentences
- Preview text uses punctuation for expression where needed

### For Voice Clone
- Reference audio file path
- Exact transcript of that audio (`--ref_text`)
- New dialogue with appropriate punctuation

### For Custom Voice
- Which predefined voice to use
- Text to speak

---

## Common CLI Options

| Flag | Description |
|------|-------------|
| `--model` | Model path or HuggingFace repo ID |
| `--text` | Text to synthesize |
| `--instruct` | Voice design description (VoiceDesign model only) |
| `--voice` | Speaker name (CustomVoice model only) |
| `--ref_audio` | Reference audio for cloning (Base model) |
| `--ref_text` | Transcript of reference audio |
| `--lang_code` | Language: English, Chinese, auto |
| `--output_path` | Directory for output files |
| `--file_prefix` | Output filename prefix (files saved as `prefix_000.wav`, `prefix_001.wav`, etc.) |
| `--play` | Play audio after generation |
| `--verbose` | Show detailed generation stats |
| `--speed` | Playback speed multiplier |
| `--temperature` | Sampling temperature (default: 0.7) |

---

## Quick Reference

**Design a voice:**
```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit \
  --instruct "Voice description here..." \
  --text "Preview text matching the voice..." \
  --output_path ./voices --file_prefix myvoice --play
```

**Clone the voice:**
```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit \
  --ref_audio ./voices/myvoice_000.wav \
  --ref_text "The preview text from above..." \
  --text "New dialogue with PROPER punctuation!" \
  --output_path ./output --file_prefix dialogue --play
```

**Use predefined voice:**
```bash
mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit \
  --voice vivian \
  --text "Text to speak..." \
  --play
```
