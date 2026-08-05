# Architecture

Floatick uses Flutter for product UI and state, and a small AppKit shell for
macOS-only window behavior.

## Dependency direction

```text
presentation -> domain
presentation -> data (injected through ViewModels)
data         -> domain
app          -> features + core
macOS shell  <-> core/platform through MethodChannel
```

Feature code must not import another feature's data layer. App assembly belongs
in `lib/app`; screen-level presentation may compose injected ViewModels from
multiple features without reaching into their data implementations. Reusable
platform and visual primitives belong in `lib/core`.

## Directory layout

```text
lib/
  app/
    floatick_app.dart
    theme/
  l10n/
    app_en.arb
    app_zh.arb
  core/
    platform/
    storage/
    ui/
  features/
    notes/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
    todos/
      data/
      domain/
      presentation/
        widgets/
    updates/
      data/
      domain/
      presentation/
test/
  app/
  features/
macos/
  Runner/
tool/
  release/
```

- `domain`: immutable app models and domain concepts.
- `data`: local persistence and serialization boundaries.
- `presentation`: Views and `ChangeNotifier` ViewModels.
- `core/platform`: shared typed wrappers around native window channels.
- `core/storage`: shared storage failure types used at repository boundaries.
- `l10n`: English source copy, Simplified Chinese translations, and generated
  Flutter localization accessors.
- `macos/Runner`: transparent floating window behavior and the Sparkle update
  service; todo and note data does not cross either platform channel.

## State and persistence

`TodoViewModel`, `NoteViewModel`, `SettingsViewModel`, and `UpdateViewModel` own
presentation state. Repositories own file I/O, JSON compatibility, or typed platform-channel
boundaries. Repositories are constructor-injected so state behavior can be
tested without touching the user's home directory or launching Sparkle.

Todo data, note data, shared tags, and Floatick-owned interface settings only use `~/.floatick`.
Repositories create it on first load and never read or write another hidden
application directory. Sparkle owns its automatic-check preference in the
standard macOS application `UserDefaults`; Floatick does not duplicate that
preference in `settings.json`.

Manual update checks probe the configured appcast URL before presenting
Sparkle. An unpublished first-release feed is mapped across the platform
channel to a typed, informational state in Settings; other connectivity
failures remain recoverable errors. Sparkle still owns appcast parsing,
signature validation, download, and installation once the feed is available.

Writes are serialized by `TodoViewModel` and `NoteViewModel` to prevent
overlapping mutations from losing updates. A write failure leaves the last
persisted in-memory state unchanged and exposes a recoverable UI error.

## Testing

- Repository tests cover local JSON parsing, compatibility, and failure paths.
- ViewModel tests cover mutations, serialization order, filtering, and sorting.
- Widget tests cover the main interaction path and theme/settings behavior.
- Pull requests compile a release-mode universal macOS app in addition to
  running Flutter analysis and tests.
- `release/x.y.z` builds a private Draft Release; `vX.Y.Z` promotes the same
  accepted DMG only when its commit is reachable from `main`.
- AppKit window behavior and Sparkle installation remain native integration
  boundaries and should be smoke-tested on both Apple silicon and Intel macOS
  before a stable release.

## Architecture guardrails

- Keep platform-specific window code out of Flutter Views.
- Keep file I/O out of widgets and ViewModels.
- Add a package only when the standard library or existing platform bridge
  cannot meet the requirement cleanly.
- Split presentation widgets when they gain independent state, reuse, or test
  value; do not create one-file-per-widget ceremony.
- Preserve the local JSON contract or ship an explicit migration.
