"""Checks the App Store listing texts against App Store Connect's length limits."""
import pathlib
import re
import sys

# Name, subtitle, promotional text, keywords, description.
LIMITS = [30, 30, 170, 100, 4000]

ok = True
for path in sorted(pathlib.Path(__file__).parent.glob("*.md")):
    if path.name == "README.md":
        continue
    sections = [s.strip() for s in re.split(r"^## .*$", path.read_text(), flags=re.M)[1:]]
    for text, limit in zip(sections, LIMITS):
        status = "ok" if len(text) <= limit else "TOO LONG"
        ok &= len(text) <= limit
        print(f"{path.name}: {len(text):>4}/{limit} {status}")
    keywords = sections[3]
    if ", " in keywords:
        ok = False
        print(f"{path.name}: keywords must be separated by commas without spaces")
sys.exit(0 if ok else 1)
