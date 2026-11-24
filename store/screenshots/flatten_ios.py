"""Removes the alpha channel from the App Store screenshots (store/screenshots/ios/).

App Store Connect rejects screenshots with transparency. Run after regenerating them:
    python3 store/screenshots/flatten_ios.py
Needs Pillow.
"""
import pathlib

from PIL import Image

for path in sorted(pathlib.Path(__file__).parent.glob("ios/*/*.png")):
    image = Image.open(path)
    if image.mode == "RGB":
        continue
    background = Image.new("RGB", image.size, "white")
    background.paste(image, mask=image.getchannel("A") if "A" in image.mode else None)
    background.save(path, optimize=True)
    print(f"flattened {path}")
