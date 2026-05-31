#!/usr/bin/env python3
"""
Extract Godot project file contents from Claude JSONL conversation transcripts.
Corrected version that understands the actual JSONL structure.
"""

import json
import os

TRANSCRIPT_DIR = r"C:\Users\david\.claude\projects\C--Users-david-OneDrive-Documentos-GitHub-HUNTERRIDDLE"
OUTPUT_DIR = r"C:\Users\david\OneDrive\Documentos\GitHub\HUNTERRIDDLE\tools\recovered"

TARGET_BASENAMES = {
    'ZorroScreen.tscn', 'ZorroScreen.gd', 'LoginScreen.tscn', 'RegisterScreen.tscn',
    'login_screen.gd', 'register_screen.gd', 'LevelCardLOCKED.tscn', 'GameState.gd',
    'global_stars.gd', 'PuzzleScreen.gd', 'NavItem.tscn', 'StartMenu.tscn',
    'ProgressManager.gd', 'UserProfile.gd', 'ConfirmExitDialog.gd',
    'FoxLevels.gd', 'board.gd', 'start_menu.gd', 'AudioManager.gd',
    'Config.tscn', 'PuzzleZorro.tscn'
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

def get_text_from_content(content):
    """Extract text from a content field (str or list of dicts)."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get('type') == 'text':
                parts.append(item.get('text', ''))
            elif isinstance(item, str):
                parts.append(item)
        return '\n'.join(parts)
    return ''

def extract_from_jsonl(jsonl_path, source_name):
    """
    Extract target file contents from a JSONL file.

    The JSONL structure:
    - Each line is a JSON object with 'type' field
    - type='assistant' or type='user' messages have a 'message' field
    - message has 'content' (list of items)
    - assistant content items: type='tool_use' with name/id/input
    - user content items: type='tool_result' with tool_use_id/content

    Strategy:
    1. Collect all tool_use calls (id -> name, input, line)
    2. For each tool_result, find the matching tool_use
    3. If it's a Read of a target file, save the content
    4. Also find Write tool_use calls with target file content
    """

    try:
        with open(jsonl_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  ERROR: {e}")
        return {}

    # Build tool_use map: id -> {name, input, line}
    tool_uses = {}

    for i, raw in enumerate(lines):
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except:
            continue

        msg = obj.get('message', {})
        if not msg:
            continue

        content = msg.get('content', [])
        if not isinstance(content, list):
            continue

        for item in content:
            if not isinstance(item, dict):
                continue
            if item.get('type') == 'tool_use':
                tid = item.get('id', '')
                if tid:
                    tool_uses[tid] = {
                        'name': item.get('name', ''),
                        'input': item.get('input', {}),
                        'line': i + 1
                    }

    found = {}  # basename -> (content, source_detail)

    # Pass 2: Find Write tool_uses with target file content (the tool_use itself has the content)
    for tid, info in tool_uses.items():
        if info['name'] == 'Write':
            fp = info['input'].get('file_path', '')
            bn = os.path.basename(fp)
            if bn in TARGET_BASENAMES:
                content = info['input'].get('content', '')
                if content and len(content) > 50:
                    if bn not in found:
                        found[bn] = (content, f'{source_name} line {info["line"]} (Write)')
                        print(f"    FOUND Write: {bn} ({len(content)} chars)")

    # Pass 3: Find tool_results for Read tool_uses
    for i, raw in enumerate(lines):
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except:
            continue

        msg = obj.get('message', {})
        if not msg:
            continue

        role = msg.get('role', '')
        if role != 'user':
            continue

        content = msg.get('content', [])
        if not isinstance(content, list):
            continue

        for item in content:
            if not isinstance(item, dict):
                continue
            if item.get('type') != 'tool_result':
                continue

            tool_use_id = item.get('tool_use_id', '')
            tool_info = tool_uses.get(tool_use_id, {})

            if tool_info.get('name') != 'Read':
                continue

            fp = tool_info.get('input', {}).get('file_path', '')
            bn = os.path.basename(fp)

            if bn not in TARGET_BASENAMES:
                continue

            # Extract text content from result
            result_raw = item.get('content', '')
            result_text = get_text_from_content(result_raw)

            if result_text and len(result_text) > 50:
                # Clean up: Read tool results have line numbers like "1\tsome content"
                # Strip those if present
                if result_text and '\t' in result_text.split('\n')[0][:5]:
                    # Has line number prefix - strip them
                    cleaned_lines = []
                    for line in result_text.split('\n'):
                        if '\t' in line:
                            # Remove line number prefix (e.g., "123\t")
                            tab_idx = line.find('\t')
                            prefix = line[:tab_idx]
                            if prefix.strip().isdigit():
                                cleaned_lines.append(line[tab_idx+1:])
                            else:
                                cleaned_lines.append(line)
                        else:
                            cleaned_lines.append(line)
                    result_text = '\n'.join(cleaned_lines)

                if bn not in found:
                    found[bn] = (result_text, f'{source_name} line {i+1} (Read of {fp})')
                    print(f"    FOUND Read: {bn} ({len(result_text)} chars) from {fp}")

    return found


# Priority order: most recent sessions first, prefer later edits
JSONL_PRIORITY = [
    # Sessions where Write calls created final versions
    "5b8fb087-8b9c-4ca7-ad6f-04147ba311af.jsonl",   # has WRITE:ProgressManager, WRITE:ConfirmExitDialog
    "51a7e8c4-9ab8-4038-b563-9079fcebfef6.jsonl",   # has WRITE:UserProfile, WRITE:Config, WRITE:global_stars
    "40a697ca-6be2-4b08-a572-818d7f9d238a.jsonl",   # has WRITE:FoxLevels
    "22aa31e0-f872-4ecc-bfe6-52cf106f161c.jsonl",   # has WRITE:AudioManager
    "db0b32e1-fb23-4e18-ba25-406032a10266.jsonl",   # has WRITE:AudioManager; many reads
    "ec606b64-ee92-428b-b3ef-32f1b5a2fbb2.jsonl",   # has WRITE:login_screen, WRITE:register_screen
    # Then sessions with just reads (use as fallback)
    "0a24700d-a7b0-4967-91a9-861e59149633.jsonl",
    "1d288d79-75af-4419-97bc-2732d770b65f.jsonl",
    "741586ed-9872-4f97-93e7-04fa55815111.jsonl",
    "0790a375-1b77-48c3-8050-549d09c0e559.jsonl",
    "085cfa40-510d-4380-9f68-b5287ca1a3a0.jsonl",
    "021ab39c-336b-4564-b270-2c75aca8b730.jsonl",
    "a43dd47f-67a2-45b2-bdd6-f7619849a765.jsonl",
    "54d20d57-5979-444f-ab48-b38d94ba557f.jsonl",
    "f1809c27-c44d-4308-a1e1-8e18c4e27a6b.jsonl",
    "f6af44f1-e0f8-4f08-96d4-e65309b46078.jsonl",
    "1ff3b7c4-75c6-4fee-935c-f68a6f11a28f.jsonl",
]

# Accumulated results: we keep the MOST RECENT version (earliest in priority list = most recent edits)
all_found = {}  # basename -> (content, source_detail)

print("Searching JSONL transcripts...")
print()

for jsonl_name in JSONL_PRIORITY:
    jsonl_path = os.path.join(TRANSCRIPT_DIR, jsonl_name)
    if not os.path.exists(jsonl_path):
        continue

    fsize = os.path.getsize(jsonl_path)
    print(f"Scanning {jsonl_name} ({fsize//1024}K)...")

    found = extract_from_jsonl(jsonl_path, jsonl_name)

    # Merge: for files not yet found, add them;
    # For Write results, they take priority over Read results
    for bn, (content, source) in found.items():
        if bn not in all_found:
            all_found[bn] = (content, source)
        elif 'Write' in source and 'Write' not in all_found[bn][1]:
            # Override a Read result with a Write result (Write = the actual final written content)
            print(f"    OVERRIDING {bn} with Write version")
            all_found[bn] = (content, source)

print()
print("=" * 70)
print("SAVING RESULTS:")
print("=" * 70)

for bn in sorted(TARGET_BASENAMES):
    if bn in all_found:
        content, source = all_found[bn]
        out_path = os.path.join(OUTPUT_DIR, bn)
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  SAVED: {bn} ({len(content)} chars)")
        print(f"    Source: {source}")
    else:
        print(f"  MISSING: {bn}")

print()
print(f"Recovered {len(all_found)}/{len(TARGET_BASENAMES)} target files.")
print()
print("Files in recovered directory:")
for fn in sorted(os.listdir(OUTPUT_DIR)):
    sz = os.path.getsize(os.path.join(OUTPUT_DIR, fn))
    print(f"  {fn} ({sz} bytes)")
