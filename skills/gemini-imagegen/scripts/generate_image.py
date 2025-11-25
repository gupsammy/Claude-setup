#!/usr/bin/env python3
"""
Generate images from text prompts using Gemini API.

Usage:
    python generate_image.py "prompt" output.png [options]

Options:
    --model, -m    Model: gemini-2.5-flash-image (default) or gemini-3-pro-image-preview
    --aspect, -a   Aspect ratio: 1:1, 16:9, 9:16, etc. (Pro only)
    --size, -s     Resolution: 1K, 2K, 4K (Pro only)
    --grounding, -g  Enable Google Search grounding (Pro only)

Examples:
    python generate_image.py "A cat in space" cat.png
    python generate_image.py "Logo for 'Acme Corp'" logo.png --model gemini-3-pro-image-preview --aspect 1:1
    python generate_image.py "Current weather in NYC" weather.png -m gemini-3-pro-image-preview -g

Environment:
    GEMINI_API_KEY - Required API key
"""

import argparse
import os
import sys

from google import genai
from google.genai import types
from gemini_utils import extract_image_and_text, save_prompt_log


def generate_image(
    prompt: str,
    output_path: str,
    model: str = "gemini-2.5-flash-image",
    aspect_ratio: str | None = None,
    image_size: str | None = None,
    google_search: bool = False,
) -> str | None:
    """Generate an image from a text prompt.

    Args:
        prompt: Text description of the image to generate
        output_path: Path to save the generated image
        model: Gemini model to use
        aspect_ratio: Aspect ratio (1:1, 16:9, 9:16, etc.)
        image_size: Resolution (1K, 2K, 4K - 4K only for pro model)
        google_search: Enable Google Search grounding (Pro model only)

    Returns:
        Any text response from the model, or None
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise EnvironmentError("GEMINI_API_KEY environment variable not set")

    client = genai.Client(api_key=api_key)

    # Build config
    config_kwargs = {"response_modalities": ["TEXT", "IMAGE"]}

    # image_config only works with gemini-3-pro-image-preview
    if "pro" in model.lower() and (aspect_ratio or image_size):
        image_config_kwargs = {}
        if aspect_ratio:
            image_config_kwargs["aspectRatio"] = aspect_ratio  # camelCase!
        if image_size:
            image_config_kwargs["imageSize"] = image_size  # camelCase!
        config_kwargs["image_config"] = types.ImageConfig(**image_config_kwargs)

    # Google Search grounding (Pro model only)
    if google_search and "pro" in model.lower():
        config_kwargs["tools"] = [{"google_search": {}}]

    config = types.GenerateContentConfig(**config_kwargs)
    
    response = client.models.generate_content(
        model=model,
        contents=[prompt],
        config=config,
    )
    
    image, text_response = extract_image_and_text(response)

    if not image:
        raise RuntimeError("No image was generated. Check your prompt and try again.")

    image.save(output_path)
    save_prompt_log(output_path, prompt)
    return text_response


def main():
    parser = argparse.ArgumentParser(
        description="Generate images from text prompts using Gemini API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("prompt", help="Text prompt describing the image")
    parser.add_argument("output", help="Output file path (e.g., output.png)")
    parser.add_argument(
        "--model", "-m",
        default="gemini-2.5-flash-image",
        choices=["gemini-2.5-flash-image", "gemini-3-pro-image-preview"],
        help="Model to use (default: gemini-2.5-flash-image)"
    )
    parser.add_argument(
        "--aspect", "-a",
        choices=["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"],
        help="Aspect ratio"
    )
    parser.add_argument(
        "--size", "-s",
        choices=["1K", "2K", "4K"],
        help="Image resolution (4K only available with pro model)"
    )
    parser.add_argument(
        "--grounding", "-g",
        action="store_true",
        help="Enable Google Search grounding (Pro model only)"
    )

    args = parser.parse_args()

    try:
        text = generate_image(
            prompt=args.prompt,
            output_path=args.output,
            model=args.model,
            aspect_ratio=args.aspect,
            image_size=args.size,
            google_search=args.grounding,
        )
        
        print(f"Image saved to: {args.output}")
        if text:
            print(f"Model response: {text}")
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
