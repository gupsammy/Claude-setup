import json
import sys
import subprocess
import re

try:
    # Load the JSON data sent from Claude Code via stdin
    input_data = json.loads(sys.stdin.read())
except json.JSONDecodeError as e:
    print(f"Error decoding JSON: {e}", file=sys.stderr)
    sys.exit(1)

# Extract the tool input and the specific file path that was modified
tool_input = input_data.get("tool_input", {})
file_path = tool_input.get("file_path")

# Proceed only if the file path is a TypeScript or TSX file
if file_path and re.search(r"\.(ts|tsx)$", file_path):
    try:
        # Run the TypeScript compiler to check for type errors
        subprocess.run(
            [
                "npx",
                "tsc",
                "--noEmit",
                "--skipLibCheck",
                file_path,
            ],
            check=True,          # Raise an exception if the command fails
            capture_output=True, # Capture stdout and stderr
            text=True            # Decode output as text
        )
    except subprocess.CalledProcessError as e:
        # If tsc finds errors, it exits with a non-zero status code, raising this exception.
        # Print a warning message to stderr.
        print(f"TypeScript errors detected - please review:", file=sys.stderr)
        
        # Print the detailed errors from tsc to stderr.
        if e.stdout:
            print(e.stdout, file=sys.stderr)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
            
        # Exit with code 2, which signals a "blocking error" to Claude Code.
        # This prompts Claude to process the error feedback.
        sys.exit(2)