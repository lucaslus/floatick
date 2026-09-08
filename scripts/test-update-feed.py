"""Regression checks with ephemeral keys: python3 scripts/test-update-feed.py SPARKLE_BIN."""
import base64
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("feed", Path(__file__).with_name("verify-update-feed.py"))
feed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feed)
signer = Path(sys.argv.pop(1)) / "sign_update"


class SignedFeedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.key = base64.b64encode(os.urandom(32)).decode()
        self.archive = self.root / "Floatick-0.4.2-macos-universal.dmg"
        self.archive.write_bytes(b"signed update fixture")
        self.xml = self.root / "appcast.xml"
        sig = self.sign(self.archive, "-p").strip()
        self.xml.write_text(f'''<?xml version="1.0"?><rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item><sparkle:shortVersionString>0.4.2</sparkle:shortVersionString><enclosure url="https://example.test/{self.archive.name}" length="{self.archive.stat().st_size}" sparkle:edSignature="{sig}"/></item></channel></rss>''')
        self.sign(self.xml)

    def sign(self, path, *args):
        return subprocess.check_output([str(signer), "--ed-key-file", "-", *args, str(path)],
                                       input=self.key, text=True)

    def verify(self):
        with patch.dict(os.environ, {"SPARKLE_ED_PRIVATE_KEY": self.key}):
            feed.verify(self.xml, signer, "https://example.test/", "0.4.2")

    def test_signed_feed_and_archive(self):
        self.verify()

    def test_tampered_feed_is_rejected(self):
        self.xml.write_text(self.xml.read_text().replace("0.4.2", "0.4.9"))
        with self.assertRaises(subprocess.CalledProcessError):
            self.verify()

    def test_same_length_tampered_archive_is_rejected(self):
        self.archive.write_bytes(b"tamper" + self.archive.read_bytes()[6:])
        with self.assertRaises(subprocess.CalledProcessError):
            self.verify()

    def test_unsigned_enclosure_is_rejected(self):
        import re
        self.xml.write_text(re.sub(r' sparkle:edSignature="[^"]+"', '', self.xml.read_text()))
        self.sign(self.xml)
        with self.assertRaisesRegex(ValueError, "unsigned"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
