"""
Utility functions for Gemini Image Generation.

Works with google-genai SDK v1.52.0+
"""
import os
from datetime import datetime
from io import BytesIO
from pathlib import Path

from PIL import Image


# Default output directory for generated images
DEFAULT_OUTPUT_DIR = Path.home() / "Documents" / "generated images"


def get_output_dir(custom_dir: str | None = None) -> Path:
    """
    Get the output directory for generated images.

    Args:
        custom_dir: Optional custom directory path

    Returns:
        Path object for the output directory (created if needed)
    """
    if custom_dir:
        output_dir = Path(custom_dir)
    else:
        output_dir = DEFAULT_OUTPUT_DIR

    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def save_prompt_log(image_path: str, prompt: str, source_images: list[str] | None = None):
    """
    Save the prompt used to generate an image as a companion .md file.

    Args:
        image_path: Path to the generated image
        prompt: The prompt used to generate/edit the image
        source_images: Optional list of source image paths (for edits/compositions)
    """
    image_path = Path(image_path)
    log_path = image_path.with_suffix(".md")

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    content = f"# Image Generation Log\n\n"
    content += f"**Generated**: {timestamp}\n\n"
    content += f"**Output**: `{image_path.name}`\n\n"

    if source_images:
        content += f"**Source Images**:\n"
        for src in source_images:
            content += f"- `{src}`\n"
        content += "\n"

    content += f"## Prompt\n\n```\n{prompt}\n```\n"

    log_path.write_text(content)


def extract_image_and_text(response):
    """
    Extract image and text from response parts.

    Args:
        response: GenerateContentResponse object

    Returns:
        Tuple of (PIL.Image or None, str or None)
    """
    # SDK v1.52.0+ has response.parts directly
    parts = response.parts if hasattr(response, 'parts') else response.candidates[0].content.parts

    text_response = None
    image_response = None

    for part in parts:
        if part.text is not None:
            text_response = part.text
        elif part.inline_data is not None:
            # Convert bytes to PIL Image
            image_bytes = part.inline_data.data
            image_response = Image.open(BytesIO(image_bytes))

    return image_response, text_response
