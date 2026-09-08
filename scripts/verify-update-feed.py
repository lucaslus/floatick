"""Validate the feed and verify signatures using the pinned Sparkle signing tool.

The private key is read by sign_update through stdin; never include it in argv.
Run only after generate_appcast has matched it to the packaged public key.
"""
import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def verify(feed: Path, signer: Path, prefix: str, version: str):
    key = os.environ["SPARKLE_ED_PRIVATE_KEY"]
    subprocess.run([str(signer), "--verify", "--ed-key-file", "-", str(feed)],
                   input=key, text=True, check=True)
    ns = {"s": "http://www.andymatuschak.org/xml-namespaces/sparkle"}
    items = ET.parse(feed).findall("./channel/item")
    if len(items) != 1 or items[0].findtext("s:shortVersionString", namespaces=ns) != version:
        raise ValueError("Expected exactly one update for the release version")
    enclosure = items[0].find("enclosure")
    name = f"Floatick-{version}-macos-universal.dmg"
    archive = feed.parent / name
    if enclosure is None or enclosure.get("url") != prefix + name:
        raise ValueError("Unexpected update download URL")
    if int(enclosure.get("length", "0")) != archive.stat().st_size:
        raise ValueError("Update length does not match release artifact")
    signature = enclosure.get("{" + ns["s"] + "}edSignature")
    if not signature:
        raise ValueError("Update archive is unsigned; check the packaged public key")
    subprocess.run([str(signer), "--verify", "--ed-key-file", "-", str(archive), signature],
                   input=key, text=True, check=True)
    print("Update feed and release archive signatures verified.")


if __name__ == "__main__":
    verify(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4])
