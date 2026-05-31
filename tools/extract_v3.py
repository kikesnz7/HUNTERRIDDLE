#!/usr/bin/env python3
"""
Extract Godot project file contents - v3.
Strategy: For each target file, find ALL versions across all JSONL files.
Then pick the best version:
  - Write versions are "what Claude created/rewrote"
  - Read versions reflect "what the file looked like at that time"
  - Largest non-trivially-small version is usually most complete
  - But we also want the most recent session's version

Key insight: sessions go chronologically.
  db0b32e1 = May 26 (oldest)
  5b8fb087 = ?
  0a24700d = ?
  40a697ca = ?
  51a7e8c4 = ?
  a43dd47f = ?
  741586ed = May 29
  1d288d79 = May 29
  0790a375 = May 27
  085cfa40 = May 31
  021ab39c = May 30
  f6af44f1 = May 30
  ec606b64 = ?
  22aa31e0 = current

For PuzzleScreen.gd: 085cfa40 (May 31) has 20731 chars - most recent and largest
For ZorroScreen.gd: 1d288d79 (May 29) has 9334 chars vs 5b's 6637
For board.gd: 0790a375 has 12482 chars (largest)
For global_stars.gd: 51a7e8c4 Write=2769 vs 1d288d79 Read=5499 -> 1d has larger read
For GameState.gd: 0790a375 has 797 chars vs 255

We need to pick versions strategically per file.
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


def clean_line_numbers(text):
    """Remove cat -n style line number prefixes (e.g. '123\t')."""
    if not text:
        return text
    lines = text.split('\n')
    if not lines:
        return text
    # Check first non-empty line
    first = next((l for l in lines if l.strip()), '')
    if '\t' not in first[:8]:
        return text  # No line numbers
    prefix = first.split('\t')[0]
    if not prefix.strip().isdigit():
        return text  # Not a line number prefix

    cleaned = []
    for line in lines:
        tab_idx = line.find('\t')
        if tab_idx >= 0:
            pre = line[:tab_idx]
            if pre.strip().isdigit():
                cleaned.append(line[tab_idx + 1:])
            else:
                cleaned.append(line)
        else:
            cleaned.append(line)
    return '\n'.join(cleaned)


def extract_all_versions(jsonl_path, source_name):
    """Extract ALL versions of ALL target files from a JSONL file."""
    try:
        with open(jsonl_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
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

    found = {}  # basename -> list of (content_text, version_type, line, source_detail)

    # Write tool_uses
    for tid, info in tool_uses.items():
        if info['name'] == 'Write':
            fp = info['input'].get('file_path', '')
            bn = os.path.basename(fp)
            if bn in TARGET_BASENAMES:
                content = info['input'].get('content', '')
                if content and len(content) > 50:
                    if bn not in found:
                        found[bn] = []
                    found[bn].append((content, 'Write', info['line'], f'{source_name}:{info["line"]}(Write)'))

    # Tool results for Read calls
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
        if msg.get('role') != 'user':
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
            result_raw = item.get('content', '')
            result_text = get_text_from_content(result_raw)
            result_text = clean_line_numbers(result_text)
            if result_text and len(result_text) > 50:
                if bn not in found:
                    found[bn] = []
                found[bn].append((result_text, 'Read', i + 1, f'{source_name}:{i+1}(Read:{fp})'))

    return found


# All JSONL files (including ones not in priority before)
ALL_JSONLS = [f for f in os.listdir(TRANSCRIPT_DIR) if f.endswith('.jsonl')]

# Collect ALL versions of every file
all_versions = {}  # basename -> list of (content, type, line, detail, jsonl_name)

print("Collecting ALL versions from ALL JSONL files...")
for jsonl_name in sorted(ALL_JSONLS):
    jsonl_path = os.path.join(TRANSCRIPT_DIR, jsonl_name)
    fsize = os.path.getsize(jsonl_path) // 1024
    print(f"  {jsonl_name} ({fsize}K)...")
    found = extract_all_versions(jsonl_path, jsonl_name)
    for bn, versions in found.items():
        if bn not in all_versions:
            all_versions[bn] = []
        for (content, vtype, line, detail) in versions:
            all_versions[bn].append((content, vtype, line, detail, jsonl_name))

print()
print("=" * 70)
print("VERSION ANALYSIS:")
print("=" * 70)

# For each file, show all versions and pick the best
final = {}  # basename -> (content, detail)

for bn in sorted(TARGET_BASENAMES):
    versions = all_versions.get(bn, [])
    if not versions:
        print(f"\n{bn}: MISSING (no versions found)")
        continue

    print(f"\n{bn}: {len(versions)} versions found")
    for i, (content, vtype, line, detail, jsonl) in enumerate(versions):
        print(f"  [{i}] {vtype} {len(content)}chars from {jsonl}")

    # Strategy: Pick the largest Write version if it exists and is substantial,
    # otherwise pick the largest overall.
    # Exception: if the Write is much smaller than a Read, the Read might be more complete.
    write_versions = [(c, vt, l, d, j) for (c, vt, l, d, j) in versions if vt == 'Write']
    read_versions  = [(c, vt, l, d, j) for (c, vt, l, d, j) in versions if vt == 'Read']

    # Find largest write and largest read
    best_write = max(write_versions, key=lambda x: len(x[0])) if write_versions else None
    best_read  = max(read_versions,  key=lambda x: len(x[0])) if read_versions  else None

    chosen = None
    reason = ""

    if best_write and best_read:
        wlen = len(best_write[0])
        rlen = len(best_read[0])
        # If write is at least 80% of the largest read, prefer write (it's Claude's final output)
        # But if read is much larger (>1.5x), it might contain more edits done after the write
        if rlen > wlen * 1.5:
            chosen = best_read
            reason = f"Read ({rlen}c) >> Write ({wlen}c)"
        else:
            chosen = best_write
            reason = f"Write ({wlen}c) >= Read ({rlen}c)*0.8"
    elif best_write:
        chosen = best_write
        reason = "Only Write available"
    elif best_read:
        chosen = best_read
        reason = "Only Read available"

    if chosen:
        content, vtype, line, detail, jsonl = chosen
        final[bn] = (content, detail)
        print(f"  CHOSEN: {reason}")
        print(f"  -> {detail}")

print()
print("=" * 70)
print("SAVING:")
print("=" * 70)

for bn in sorted(TARGET_BASENAMES):
    if bn in final:
        content, detail = final[bn]
        out_path = os.path.join(OUTPUT_DIR, bn)
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  SAVED: {bn} ({len(content)} chars)")
    else:
        print(f"  MISSING: {bn}")

print()
print(f"Recovered {len(final)}/{len(TARGET_BASENAMES)} files.")
print()
print("Final files in recovered directory:")
for fn in sorted(os.listdir(OUTPUT_DIR)):
    if fn.endswith('.py'):
        continue
    sz = os.path.getsize(os.path.join(OUTPUT_DIR, fn))
    print(f"  {fn}: {sz} bytes")
