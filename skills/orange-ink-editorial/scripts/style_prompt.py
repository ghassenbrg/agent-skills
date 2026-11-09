#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
patterns = (ROOT / "references" / "prompt-patterns.md").read_text()
print(patterns)
