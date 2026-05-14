#!/usr/bin/env python3
"""
Copy MQGram brand assets (logo + app icon) into Telegram-iOS asset catalogs.

Place your files first:
    MQGram/Assets/logo.png      # 1024x1024 brand logo (used for settings icon)
    MQGram/Assets/appicon.png   # 1024x1024 iOS App Icon

Then run from repo root:
    python3 MQGram/Patches/apply_assets.py
"""

import shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
ASSETS_DIR = ROOT / 'MQGram' / 'Assets'

TARGETS = [
    # (source-in-Assets, destination)
    ('appicon.png', 'Telegram/Telegram-iOS/DefaultAppIcon.xcassets/AppIconLLC.appiconset/Swiftgram.png'),
    # SwiftgramSettings.imageset uses a PDF currently. Put PNG aside; many imagesets
    # accept PNGs if Contents.json points at .png (rewrite Contents.json below).
    ('logo.png', 'Swiftgram/SGSettingsUI/Images.xcassets/SwiftgramSettings.imageset/MQGramSettings.png'),
]

CONTENTS_JSON = '''{
  "images" : [
    {
      "filename" : "MQGramSettings.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
'''

def main():
    if not (ROOT / 'WORKSPACE').exists() and not (ROOT / 'MODULE.bazel').exists():
        print(f'Error: {ROOT} is not a Telegram-iOS root.')
        sys.exit(1)

    missing = []
    for src, _ in TARGETS:
        if not (ASSETS_DIR / src).exists():
            missing.append(src)
    if missing:
        print(f'Missing files in {ASSETS_DIR}: {missing}')
        print('Put your logo.png and appicon.png there and re-run.')
        sys.exit(1)

    for src, dst in TARGETS:
        src_path = ASSETS_DIR / src
        dst_path = ROOT / dst
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src_path, dst_path)
        print(f'copied {src} -> {dst}')

    # Rewrite SwiftgramSettings imageset Contents.json to reference our PNG
    settings_imageset = ROOT / 'Swiftgram/SGSettingsUI/Images.xcassets/SwiftgramSettings.imageset'
    if settings_imageset.exists():
        old_pdf = settings_imageset / 'Swiftgram.pdf'
        if old_pdf.exists():
            old_pdf.unlink()
        with open(settings_imageset / 'Contents.json', 'w', encoding='utf-8') as f:
            f.write(CONTENTS_JSON)
        print(f'rewrote {settings_imageset / "Contents.json"}')

    print('done')

if __name__ == '__main__':
    main()
