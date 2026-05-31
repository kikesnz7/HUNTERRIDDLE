#!/usr/bin/env python3
"""
Extract Godot project file contents from Claude JSONL conversation transcripts.
"""

import json
import os
import re
import sys

TRANSCRIPT_DIR = r"C:\Users\david\.claude\projects\C--Users-david-OneDrive-Documentos-GitHub-HUNTERRIDDLE"
OUTPUT_DIR = r"C:\Users\david\OneDrive\Documentos\GitHub\HUNTERRIDDLE\tools\recovered"

TARGET_FILES = [
    "ZorroScreen.tscn",
    "ZorroScreen.gd",
    "LoginScreen.tscn",
    "RegisterScreen.tscn",
    "login_screen.gd",
    "register_screen.gd",
    "LevelCardLOCKED.tscn",
    "GameState.gd",
    "global_stars.gd",
    "PuzzleScreen.gd",
    "NavItem.tscn",
    "StartMenu.tscn",
    "ProgressManager.gd",
    "UserProfile.gd",
    "ConfirmExitDialog.gd",
    # Also common related files
    "FoxLevels.gd",
    "board.gd",
    "start_menu.gd",
    "AudioManager.gd",
    "Config.tscn",
    "PuzzleZorro.tscn",
]

# JSONL files to search (most recent first)
JSONL_FILES = [
    "22aa31e0-f872-4ecc-bfe6-52cf106f161c.jsonl",
    "021ab39c-336b-4564-b270-2c75aca8b730.jsonl",
    "f6af44f1-e0f8-4f08-96d4-e65309b46078.jsonl",
    "085cfa40-510d-4380-9f68-b5287ca1a3a0.jsonl",
    "1d288d79-75af-4419-97bc-2732d770b65f.jsonl",
    "741586ed-9872-4f97-93e7-04fa55815111.jsonl",
    "0790a375-1b77-48c3-8050-549d09c0e559.jsonl",
    "db0b32e1-fb23-4e18-ba25-406032a10266.jsonl",
    # Also check others
    "51a7e8c4-9ab8-4038-b563-9079fcebfef6.jsonl",
    "54d20d57-5979-444f-ab48-b38d94ba557f.jsonl",
    "6377db8e-9d39-4ec9-9b81-a69c9e1cf649.jsonl",
    "a58e9f80-eb43-478d-8ba8-7a3c201d3f59.jsonl",
    "ec606b64-ee92-428b-b3ef-32f1b5a2fbb2.jsonl",
    "f1809c27-c44d-4308-a1e1-8e18c4e27a6b.jsonl",
    "1ff3b7c4-75c6-4fee-935c-f68a6f11a28f.jsonl",
]

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Track what we've recovered and from where
recovered = {}  # filename -> (content, source_jsonl)

def extract_text_from_content(content):
    """Extract text string from a content field which can be string or list."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    parts.append(item.get("text", ""))
                elif item.get("type") == "tool_result":
                    # Nested tool result
                    inner = item.get("content", "")
                    parts.append(extract_text_from_content(inner))
            elif isinstance(item, str):
                parts.append(item)
        return "\n".join(parts)
    return ""

def find_file_content_in_text(text, target_filename):
    """
    Try to find the content of a specific file in a text block.
    Looks for patterns like file content after Read tool results.
    """
    if not text or target_filename not in text:
        return None
    return text

def check_write_tool(tool_use, target_files):
    """Check if a tool_use is a Write call for one of our target files."""
    if tool_use.get("name") != "Write":
        return None, None

    input_data = tool_use.get("input", {})
    file_path = input_data.get("file_path", "")
    content = input_data.get("content", "")

    if not file_path or not content:
        return None, None

    basename = os.path.basename(file_path)
    for target in target_files:
        if basename == target:
            return target, content

    return None, None

def check_read_tool_result(messages, idx, target_files):
    """
    After a Read tool_use, the next message should be the result.
    Check if the read result contains target file content.
    """
    pass

def search_jsonl(jsonl_path, source_name):
    """Search a JSONL file for target file contents."""
    found = {}

    try:
        with open(jsonl_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  ERROR reading {source_name}: {e}")
        return found

    print(f"  Scanning {source_name} ({len(lines)} lines)...")

    # Parse all lines into message objects
    messages = []
    for line_num, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            messages.append((line_num + 1, obj))
        except json.JSONDecodeError:
            pass

    # Strategy 1: Find Write tool calls (assistant wrote the file)
    for line_num, msg in messages:
        msg_type = msg.get("type", "")
        role = msg.get("role", "")

        # Check for tool_use in assistant messages
        if role == "assistant":
            content = msg.get("content", [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_use":
                        target, file_content = check_write_tool(item, TARGET_FILES)
                        if target and file_content:
                            if target not in found:
                                found[target] = file_content
                                print(f"    FOUND via Write tool: {target} (line {line_num})")

    # Strategy 2: Find tool_result messages that contain file read content
    # Tool results come after tool_use calls. We need to find Read tool calls
    # and then match them with their results.

    # First pass: collect all tool_use calls with their IDs
    tool_uses = {}  # tool_use_id -> {name, input}
    for line_num, msg in messages:
        role = msg.get("role", "")
        if role == "assistant":
            content = msg.get("content", [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_use":
                        tool_id = item.get("id", "")
                        tool_name = item.get("name", "")
                        tool_input = item.get("input", {})
                        if tool_id:
                            tool_uses[tool_id] = {
                                "name": tool_name,
                                "input": tool_input,
                                "line": line_num
                            }

    # Second pass: find tool_result messages
    for line_num, msg in messages:
        role = msg.get("role", "")
        if role == "user":
            content = msg.get("content", [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_result":
                        tool_use_id = item.get("tool_use_id", "")
                        result_content = item.get("content", "")

                        # Get the corresponding tool_use
                        tool_use_info = tool_uses.get(tool_use_id, {})
                        tool_name = tool_use_info.get("name", "")
                        tool_input = tool_use_info.get("input", {})

                        if tool_name == "Read":
                            file_path = tool_input.get("file_path", "")
                            basename = os.path.basename(file_path)

                            # Check if this is a target file
                            for target in TARGET_FILES:
                                if basename == target:
                                    # Extract text content from result
                                    result_text = extract_text_from_content(result_content)
                                    if result_text and len(result_text) > 50:
                                        if target not in found:
                                            found[target] = result_text
                                            print(f"    FOUND via Read result: {target} (line {line_num}, path: {file_path})")
                                    break

                        elif tool_name == "Write":
                            # Sometimes write results confirm the write
                            pass

    # Strategy 3: Search for file content patterns in assistant text messages
    # Look for content that starts with Godot scene/script patterns
    for line_num, msg in messages:
        role = msg.get("role", "")
        if role == "assistant":
            content = msg.get("content", [])
            text = extract_text_from_content(content)

            # Look for GDScript or Godot scene markers in code blocks
            if "```" in text:
                # Find code blocks
                code_blocks = re.findall(r'```(?:gdscript|gd|tscn)?\n(.*?)```', text, re.DOTALL)
                for block in code_blocks:
                    # Check if block content looks like target file
                    for target in TARGET_FILES:
                        if target not in found:
                            stem = os.path.splitext(target)[0]
                            ext = os.path.splitext(target)[1]

                            # For .gd files, check for class or func patterns
                            if ext == ".gd" and len(block) > 100:
                                # Check if the block mentions the file name in comments or extends
                                if stem.lower() in block.lower() or f"# {target}" in block:
                                    found[target] = block
                                    print(f"    FOUND via code block: {target} (line {line_num})")

                            # For .tscn files, check for scene header
                            elif ext == ".tscn" and "[gd_scene" in block:
                                if stem.lower() in block.lower():
                                    found[target] = block
                                    print(f"    FOUND via tscn block: {target} (line {line_num})")

    return found

# Main search loop
print("Starting transcript search...")
print(f"Output directory: {OUTPUT_DIR}")
print()

for jsonl_name in JSONL_FILES:
    jsonl_path = os.path.join(TRANSCRIPT_DIR, jsonl_name)
    if not os.path.exists(jsonl_path):
        print(f"Skipping {jsonl_name} (not found)")
        continue

    found = search_jsonl(jsonl_path, jsonl_name)

    for target, content in found.items():
        if target not in recovered:
            recovered[target] = (content, jsonl_name)

    # Check if we have everything
    missing = [t for t in TARGET_FILES if t not in recovered]
    if not missing:
        print("All target files found!")
        break

print()
print("=" * 60)
print("RESULTS:")
print("=" * 60)

for target in TARGET_FILES:
    if target in recovered:
        content, source = recovered[target]
        out_path = os.path.join(OUTPUT_DIR, target)
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  SAVED: {target} ({len(content)} chars) from {source}")
    else:
        print(f"  MISSING: {target}")

print()
print(f"Recovered {len(recovered)}/{len(TARGET_FILES)} target files.")

# Also list everything in recovered dir
print()
print("Files in recovered directory:")
for f in sorted(os.listdir(OUTPUT_DIR)):
    size = os.path.getsize(os.path.join(OUTPUT_DIR, f))
    print(f"  {f} ({size} bytes)")
