#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "google-genai>=1.0.0",
#     "pillow>=10.0.0",
# ]
# ///
"""
Generate and edit images using Gemini Pro Image API.

Supports three modes:
  - t2i (text-to-image): Generate from prompt only
  - i2i (image-to-image): Edit a single image with a prompt
  - Multi-reference: Compose from multiple images (up to 14)

Usage:
    # Text-to-image
    uv run generate.py --prompt "A cat in space" --output cat.png

    # Image editing
    uv run generate.py --prompt "Make it blue" --input photo.png --output edited.png

    # Multi-reference composition
    uv run generate.py --prompt "Combine cat from first with background from second" \\
        --input cat.png --input background.png --output composite.png

    # Batch generation (up to 4 images, async parallel)
    uv run generate.py --prompt "A cat in space" --output cat.png --batch 4

Options:
    --prompt, -p     Image description or edit instruction (required)
    --output, -o     Output file path (required)
    --input, -i      Input image(s) for editing (repeatable, up to 14)
    --aspect, -a     Aspect ratio (1:1, 16:9, 9:16, etc.)
    --resolution, -r Resolution: 1K, 2K, 4K (default: auto-detect or 1K)
    --grounding, -g  Enable Google Search grounding
    --batch, -b      Generate multiple variations (1-4, default: 1)

Environment:
    GEMINI_API_KEY - Required API key
"""

import argparse
import asyncio
import os
import sys
from datetime import datetime
from io import BytesIO
from pathlib import Path


MODEL = "gemini-3-pro-image-preview"
DEFAULT_OUTPUT_DIR = Path.home() / "Documents" / "generated images"


def get_api_key() -> str | None:
    """Get API key from environment."""
    return os.environ.get("GEMINI_API_KEY")


def detect_resolution(images: list) -> str:
    """Auto-detect appropriate resolution from input image dimensions."""
    if not images:
        return "1K"

    max_dim = 0
    for img in images:
        width, height = img.size
        max_dim = max(max_dim, width, height)

    if max_dim >= 3000:
        return "4K"
    elif max_dim >= 1500:
        return "2K"
    return "1K"


def save_prompt_log(
    log_path: Path,
    prompt: str,
    output_images: list[Path],
    source_images: list[str] | None = None
):
    """Save the prompt used to generate images as a single .md file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    content = f"# Image Generation Log\n\n"
    content += f"**Generated**: {timestamp}\n\n"

    if len(output_images) == 1:
        content += f"**Output**: `{output_images[0].name}`\n\n"
    else:
        content += f"**Outputs**:\n"
        for img in output_images:
            content += f"- `{img.name}`\n"
        content += "\n"

    if source_images:
        content += f"**Source Images**:\n"
        for src in source_images:
            content += f"- `{src}`\n"
        content += "\n"

    content += f"## Prompt\n\n```\n{prompt}\n```\n"

    log_path.write_text(content)


def extract_image_and_text(response):
    """Extract image and text from response parts."""
    parts = response.parts if hasattr(response, 'parts') else response.candidates[0].content.parts

    text_response = None
    image_response = None

    for part in parts:
        if part.text is not None:
            text_response = part.text
        elif part.inline_data is not None:
            from PIL import Image
            image_bytes = part.inline_data.data
            image_response = Image.open(BytesIO(image_bytes))

    return image_response, text_response


def copy_images(images: list) -> list:
    """Create deep copies of PIL Images to avoid thread-safety issues."""
    if not images:
        return None
    return [img.copy() for img in images]


async def generate_image_async(
    client,
    prompt: str,
    output_path: Path,
    input_images: list | None = None,
    aspect_ratio: str | None = None,
    resolution: str | None = None,
    grounding: bool = False,
) -> str | None:
    """
    Generate or edit an image asynchronously.

    Args:
        client: The genai Client instance
        prompt: Text description or edit instruction
        output_path: Path to save the output image
        input_images: Optional list of PIL Image objects for editing/composition
        aspect_ratio: Aspect ratio (1:1, 16:9, etc.)
        resolution: Output resolution (1K, 2K, 4K)
        grounding: Enable Google Search grounding

    Returns:
        Any text response from the model, or None
    """
    from google.genai import types

    # Auto-detect resolution if not specified
    if resolution is None:
        resolution = detect_resolution(input_images or [])

    # Build contents: images first (if any), then prompt
    if input_images:
        contents = input_images + [prompt]
    else:
        contents = [prompt]

    # Build config
    config_kwargs = {"response_modalities": ["TEXT", "IMAGE"]}

    # Image config for aspect ratio and resolution
    image_config_kwargs = {}
    if aspect_ratio:
        image_config_kwargs["aspectRatio"] = aspect_ratio
    if resolution:
        image_config_kwargs["imageSize"] = resolution
    if image_config_kwargs:
        config_kwargs["image_config"] = types.ImageConfig(**image_config_kwargs)

    # Google Search grounding
    if grounding:
        config_kwargs["tools"] = [{"google_search": {}}]

    config = types.GenerateContentConfig(**config_kwargs)

    # Use async API - properly handles concurrent requests
    response = await client.aio.models.generate_content(
        model=MODEL,
        contents=contents,
        config=config,
    )

    image, text_response = extract_image_and_text(response)

    if not image:
        raise RuntimeError("No image was generated. Check your prompt and try again.")

    # Convert to RGB if needed and save as PNG
    if image.mode == 'RGBA':
        from PIL import Image as PILImage
        rgb_image = PILImage.new('RGB', image.size, (255, 255, 255))
        rgb_image.paste(image, mask=image.split()[3])
        rgb_image.save(str(output_path), 'PNG')
    elif image.mode == 'RGB':
        image.save(str(output_path), 'PNG')
    else:
        image.convert('RGB').save(str(output_path), 'PNG')

    return text_response


async def generate_single(
    client,
    idx: int,
    total: int,
    out_path: Path,
    prompt: str,
    input_images: list | None,
    aspect_ratio: str | None,
    resolution: str | None,
    grounding: bool,
) -> tuple[int, Path, str | None, Exception | None]:
    """Generate a single image, return (index, path, text, error)."""
    try:
        # Copy input images for this task to avoid concurrent access issues
        task_images = copy_images(input_images)

        text = await generate_image_async(
            client=client,
            prompt=prompt,
            output_path=out_path,
            input_images=task_images,
            aspect_ratio=aspect_ratio,
            resolution=resolution,
            grounding=grounding,
        )
        return (idx, out_path, text, None)
    except Exception as e:
        return (idx, out_path, None, e)


async def run_batch(
    client,
    output_paths: list[Path],
    prompt: str,
    input_images: list | None,
    aspect_ratio: str | None,
    resolution: str | None,
    grounding: bool,
) -> list[tuple[int, Path, str | None, Exception | None]]:
    """Run batch generation using asyncio.gather for true async parallelism."""
    total = len(output_paths)

    tasks = [
        generate_single(
            client=client,
            idx=i,
            total=total,
            out_path=path,
            prompt=prompt,
            input_images=input_images,
            aspect_ratio=aspect_ratio,
            resolution=resolution,
            grounding=grounding,
        )
        for i, path in enumerate(output_paths, 1)
    ]

    # Run all tasks concurrently with asyncio.gather
    return await asyncio.gather(*tasks)


async def async_main(args, input_images, input_paths, output_paths):
    """Async entry point for image generation."""
    from google import genai

    api_key = get_api_key()
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)

    # Create a single client instance for all requests
    client = genai.Client(api_key=api_key)

    print("Generating...")

    # Run batch with async parallelism
    batch_results = await run_batch(
        client=client,
        output_paths=output_paths,
        prompt=args.prompt,
        input_images=input_images,
        aspect_ratio=args.aspect,
        resolution=args.resolution,
        grounding=args.grounding,
    )

    # Process results
    results = []
    for idx, out_path, text, error in sorted(batch_results, key=lambda x: x[0]):
        if error:
            print(f"\n[{idx}/{args.batch}] Error: {error}", file=sys.stderr)
        else:
            full_path = out_path.resolve()
            print(f"\n[{idx}/{args.batch}] Image saved: {full_path}")
            print(f"MEDIA: {full_path}")
            if text:
                print(f"Model response: {text}")
            results.append(full_path)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Generate and edit images using Gemini Pro Image API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        "--prompt", "-p",
        required=True,
        help="Image description or edit instruction"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output file path (e.g., output.png)"
    )
    parser.add_argument(
        "--input", "-i",
        action="append",
        dest="inputs",
        help="Input image path for editing/composition (can be repeated up to 14 times)"
    )
    parser.add_argument(
        "--aspect", "-a",
        choices=["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"],
        help="Aspect ratio"
    )
    parser.add_argument(
        "--resolution", "-r",
        choices=["1K", "2K", "4K"],
        help="Output resolution (default: auto-detect from input or 1K)"
    )
    parser.add_argument(
        "--grounding", "-g",
        action="store_true",
        help="Enable Google Search grounding"
    )
    parser.add_argument(
        "--batch", "-b",
        type=int,
        choices=[1, 2, 3, 4],
        default=1,
        help="Generate multiple variations (1-4, default: 1)"
    )

    args = parser.parse_args()

    # Validate input count
    if args.inputs and len(args.inputs) > 14:
        print("Error: Maximum 14 input images allowed", file=sys.stderr)
        sys.exit(1)

    # Set up output path
    output_path = Path(args.output)
    if not output_path.parent.exists():
        output_path.parent.mkdir(parents=True, exist_ok=True)

    # Load input images if provided
    input_images = None
    input_paths = []
    if args.inputs:
        from PIL import Image
        input_images = []
        for img_path in args.inputs:
            try:
                img = Image.open(img_path)
                # Load image data into memory to avoid file handle issues
                img.load()
                input_images.append(img)
                input_paths.append(img_path)
                print(f"Loaded: {img_path} ({img.size[0]}x{img.size[1]})")
            except Exception as e:
                print(f"Error loading {img_path}: {e}", file=sys.stderr)
                sys.exit(1)

    # Determine mode for display
    if not input_images:
        mode = "t2i (text-to-image)"
    elif len(input_images) == 1:
        mode = "i2i (image editing)"
    else:
        mode = f"multi-reference ({len(input_images)} images)"

    resolution = args.resolution or detect_resolution(input_images or [])
    print(f"Mode: {mode}")
    print(f"Resolution: {resolution}")
    if args.aspect:
        print(f"Aspect ratio: {args.aspect}")
    if args.grounding:
        print("Google Search grounding: enabled")
    if args.batch > 1:
        print(f"Batch: {args.batch} images (async parallel)")

    # Generate output paths for batch
    if args.batch == 1:
        output_paths = [output_path]
    else:
        stem = output_path.stem
        suffix = output_path.suffix
        parent = output_path.parent
        output_paths = [parent / f"{stem}-{i}{suffix}" for i in range(1, args.batch + 1)]

    # Run async main
    results = asyncio.run(async_main(args, input_images, input_paths, output_paths))

    if not results:
        print("Error: No images were generated", file=sys.stderr)
        sys.exit(1)

    # Save single prompt log for all generated images
    log_path = output_path.with_suffix(".md")
    save_prompt_log(log_path, args.prompt, results, input_paths if input_paths else None)
    print(f"\nPrompt log: {log_path.resolve()}")

    print(f"Generated {len(results)}/{args.batch} images")


if __name__ == "__main__":
    main()
