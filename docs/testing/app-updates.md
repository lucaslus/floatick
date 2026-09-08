# App update validation

The Tauri client uses Sparkle 2.9.2 with an Ed25519-signed feed and archives. The
private production key remains in the protected GitHub production environment.
Unbundled development sessions deliberately report that native updates are unavailable.

## Local checks

```sh
pnpm setup:sparkle
pnpm build
cargo test --manifest-path src-tauri/Cargo.toml --locked
pnpm tauri build --bundles app
python3 scripts/verify-update-bundle.py src-tauri/target/release/bundle/macos/Floatick.app
# With the checksum-verified Sparkle tools extracted locally:
python3 scripts/test-update-feed.py /path/to/sparkle/bin
```

The feed regression suite generates temporary signing keys. It checks a valid feed,
a modified feed, a same-size modified archive, and an unsigned archive enclosure.
The stable release workflow runs these tests and verifies the real feed and DMG
signatures before promoting the candidate. Bundle checks also run in CI and on the
candidate and stable release assets.

## Native end-to-end checks performed

Tested an isolated app copy with a separate bundle identifier, a temporary signing
key, and a localhost feed. No installed user application was replaced. The fixture
kept the production application's executable and changed only bundle metadata and
signatures. Its version change was for testing, not a published release.

- Open Settings, check for updates, and display the native available-version window.
- Download a signed DMG and reach the ready-to-install window.
- Install and relaunch: the old process exits, a new process starts, and the fixture's
  bundle build changes from 13 to 14.
- Check again and confirm the native “You're up to date” result.
- Modify the signed feed and confirm a native signature error prevents the update.
- Toggle automatic checks and confirm the native preference is persisted.

Chromium and WebKit checks cover the settings unavailable state, actual version
snapshot, manual checks, duplicate-action prevention, preference failures, check
retries, and recovery after a failed settings read. Existing editor regression
checks still cover the empty caret, checklist alignment, nesting, wrapping, and saving.

## First release with this feature

Versions 0.4.0 and 0.4.1 do not contain a client updater. Those users must manually
install the first release containing this implementation. The current 0.4.1 feed is
unsigned and is correctly rejected by the new client. Publishing the new release
through the updated workflow will replace it with a signed feed and archive. Do not
turn off signature verification to accept the old feed.
