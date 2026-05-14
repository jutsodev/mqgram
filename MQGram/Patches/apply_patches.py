#!/usr/bin/env python3
"""
MQGram patcher: apply MQGram code modifications to a fresh Swiftgram/Telegram-iOS clone.

Run from repo root:
    python3 MQGram/Patches/apply_patches.py

Idempotent: each patch checks if it's already applied (by looking for an MQGram marker)
and silently skips. If the original code chunk has changed in upstream, the patch fails
loudly so you can re-target it manually.
"""

import io
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent  # repo root

PATCHES = []

def patch(rel_path, *, find, replace, marker=None, count=1):
    """Register a patch.

    find: literal CRLF-aware string to search for (must occur exactly `count` times)
    replace: replacement string
    marker: substring; if present in file, patch is considered already applied
    """
    PATCHES.append({
        'path': rel_path,
        'find': find,
        'replace': replace,
        'marker': marker if marker is not None else 'MQGram',
        'count': count,
    })

# Detect line-ending of repo
def detect_eol(path):
    with open(path, 'rb') as f:
        data = f.read(8192)
    return '\r\n' if b'\r\n' in data else '\n'

def apply_one(p):
    path = ROOT / p['path']
    if not path.exists():
        return False, f'NOT FOUND: {p["path"]}'

    with io.open(path, 'r', encoding='utf-8', newline='') as f:
        text = f.read()

    if p['marker'] in text and 'MQGram' in p['marker']:
        # Heuristic: file already touched - skip if find no longer matches
        pass

    eol = detect_eol(path)
    find = p['find'].replace('\n', eol) if '\r\n' not in p['find'] else p['find']
    replace = p['replace'].replace('\n', eol) if '\r\n' not in p['replace'] else p['replace']

    occurrences = text.count(find)
    if occurrences == 0:
        # Possibly already applied
        if 'MQGram' in text:
            # check if our marker phrase from the replacement appears
            return True, 'already applied (skipped)'
        return False, 'find pattern not found (upstream changed?)'
    if occurrences != p['count']:
        return False, f'expected {p["count"]} occurrences, found {occurrences}'

    text = text.replace(find, replace, p['count'])
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text)
    return True, 'applied'

def main():
    if not (ROOT / 'WORKSPACE').exists() and not (ROOT / 'MODULE.bazel').exists():
        print(f'Error: {ROOT} does not look like a Telegram-iOS root. Aborting.')
        sys.exit(1)

    if not PATCHES:
        print('No patches registered yet — see INTEGRATION.md for the full list.')
        print('This script is a placeholder; manual patching reference is in MQGram/INTEGRATION.md')
        return

    failed = 0
    for p in PATCHES:
        ok, msg = apply_one(p)
        status = 'OK ' if ok else 'FAIL'
        print(f'[{status}] {p["path"]}: {msg}')
        if not ok:
            failed += 1
    if failed:
        sys.exit(1)
    print('done')

if __name__ == '__main__':
    main()
