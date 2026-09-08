"""Fail a release if the packaged updater differs from its trusted configuration."""
import plistlib
import subprocess
import sys
from pathlib import Path


def verify(app: Path):
    root = Path(__file__).resolve().parents[1]
    expected = plistlib.loads((root / "src-tauri/Info.plist").read_bytes())
    actual = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    for key, value in expected.items():
        if actual.get(key) != value:
            raise ValueError(f"Packaged updater setting {key} differs from Info.plist")
    framework = app / "Contents/Frameworks/Sparkle.framework"
    for path in ["Sparkle", "Resources/Info.plist", "Versions/B/Autoupdate",
                 "Versions/B/Updater.app/Contents/MacOS/Updater",
                 "Versions/B/XPCServices/Downloader.xpc/Contents/MacOS/Downloader",
                 "Versions/B/XPCServices/Installer.xpc/Contents/MacOS/Installer"]:
        if not (framework / path).is_file():
            raise ValueError(f"Missing updater component: {path}")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    executable = app / "Contents/MacOS" / actual["CFBundleExecutable"]
    linked = subprocess.check_output(["otool", "-L", str(executable)], text=True)
    if "@rpath/Sparkle.framework/" not in linked:
        raise ValueError("Application does not link the embedded Sparkle framework")
    print("Packaged update configuration, framework, and code signatures verified.")


if __name__ == "__main__":
    verify(Path(sys.argv[1]))
