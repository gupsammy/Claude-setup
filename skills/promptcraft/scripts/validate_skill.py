#!/usr/bin/env python3
"""
Skill Validator - Validates skill structure and frontmatter for Claude Code

Usage:
    validate_skill.py <skill_directory>

Example:
    validate_skill.py ~/.claude/skills/my-skill
"""

import re
import sys
from pathlib import Path

import yaml

MAX_SKILL_NAME_LENGTH = 64

# Claude Code supported frontmatter fields
ALLOWED_FRONTMATTER = {
    "name",
    "description",
    "context",
    "model",
    "agent",
    "allowed-tools",
    "hooks",
    "user-invocable",
    "disable-model-invocation",
    "argument-hint",
    "license",
    "metadata",
}


def validate_skill(skill_path):
    """Validate a skill directory for Claude Code compatibility."""
    skill_path = Path(skill_path).expanduser().resolve()

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    content = skill_md.read_text()
    if not content.startswith("---"):
        return False, "No YAML frontmatter found (must start with ---)"

    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format (missing closing ---)"

    frontmatter_text = match.group(1)

    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        if not isinstance(frontmatter, dict):
            return False, "Frontmatter must be a YAML dictionary"
    except yaml.YAMLError as e:
        return False, f"Invalid YAML in frontmatter: {e}"

    # Check for unexpected keys
    unexpected = set(frontmatter.keys()) - ALLOWED_FRONTMATTER
    if unexpected:
        return False, f"Unexpected frontmatter key(s): {', '.join(sorted(unexpected))}"

    # Required fields
    if "name" not in frontmatter:
        return False, "Missing required 'name' field"
    if "description" not in frontmatter:
        return False, "Missing required 'description' field"

    # Validate name
    name = frontmatter.get("name", "")
    if not isinstance(name, str):
        return False, f"'name' must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        if not re.match(r"^[a-z0-9-]+$", name):
            return False, f"Name '{name}' must be hyphen-case (lowercase, digits, hyphens only)"
        if name.startswith("-") or name.endswith("-") or "--" in name:
            return False, f"Name '{name}' cannot start/end with hyphen or have consecutive hyphens"
        if len(name) > MAX_SKILL_NAME_LENGTH:
            return False, f"Name too long ({len(name)} chars). Max: {MAX_SKILL_NAME_LENGTH}"

    # Validate description
    description = frontmatter.get("description", "")
    if not isinstance(description, str):
        return False, f"'description' must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        if len(description) > 1024:
            return False, f"Description too long ({len(description)} chars). Max: 1024"
        if "[TODO" in description:
            return False, "Description contains TODO placeholder - please complete it"

    # Validate model if present
    model = frontmatter.get("model")
    if model and model not in ("haiku", "sonnet", "opus"):
        return False, f"Invalid model '{model}'. Must be: haiku, sonnet, or opus"

    # Validate context if present
    context = frontmatter.get("context")
    if context and context != "fork":
        return False, f"Invalid context '{context}'. Only 'fork' is supported"

    # Check body has content
    body = content[match.end():].strip()
    if not body:
        return False, "SKILL.md body is empty"
    if "[TODO" in body:
        return False, "SKILL.md contains TODO placeholders - please complete them"

    return True, "Skill is valid"


def main():
    if len(sys.argv) != 2:
        print("Usage: validate_skill.py <skill_directory>")
        print("Example: validate_skill.py ~/.claude/skills/my-skill")
        sys.exit(1)

    skill_path = sys.argv[1]
    print(f"Validating: {skill_path}")

    valid, message = validate_skill(skill_path)
    if valid:
        print(f"[OK] {message}")
    else:
        print(f"[ERROR] {message}")

    sys.exit(0 if valid else 1)


if __name__ == "__main__":
    main()
