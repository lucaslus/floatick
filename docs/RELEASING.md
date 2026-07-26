# Development and release workflow

Floatick uses a lightweight release-branch model. `main` is the only stable
branch, short-lived branches carry daily work, and `release/x.y.z` branches
produce private Draft Releases for manual acceptance.

Release repository: `https://github.com/lucaslushuo/floatick`

Sparkle appcast: `https://lucaslushuo.github.io/floatick/appcast.xml`

## Branch model

| Branch or tag | Purpose | Publishes binaries |
| --- | --- | --- |
| `main` | Stable integration branch; all released commits must be reachable from it | No |
| `feature/*` | Short-lived feature development | No |
| `fix/*` | Short-lived bug fixes | No |
| `release/x.y.z` | Version freeze, release-only fixes, and manual acceptance | Draft Release only |
| `vX.Y.Z` | Stable tag on the exact accepted candidate commit | Starts production approval |
| `candidate/vX.Y.Z` | Workflow-managed temporary tag for the Draft Release | Draft assets only |

Do not add a second long-lived `master` or `develop` branch. For this project,
they would duplicate `main` without providing an additional release boundary.

## Daily development

1. Create `feature/*` or `fix/*` from the latest `main`.
2. Open a pull request into `main`.
3. Wait for the required CI check. CI runs formatting, analysis, tests, a
   release-mode macOS build, and universal architecture validation.
4. Merge the pull request only after CI succeeds.

`main` is protected against force pushes and deletion. Direct pushes should not
be used for normal development.

## Build a release candidate

Create a release branch from the commit intended for the release:

```bash
git fetch origin
git switch main
git pull --ff-only
git switch -c release/0.1.0
```

Set the matching public version and an increasing positive build number:

```yaml
version: 0.1.0+1
```

Then push the branch:

```bash
git push -u origin release/0.1.0
```

Every push to `release/0.1.0` runs the Release Candidate workflow. It:

1. validates that the branch name matches `pubspec.yaml`;
2. runs formatting, analysis, and tests;
3. builds the universal release-mode macOS app;
4. normalizes embedded code to one ad-hoc identity for the unsigned candidate;
5. verifies both architectures and launches the app on the Apple silicon runner;
6. creates the DMG, SHA-256 checksum, and build manifest;
7. creates or updates a Draft Release associated with
   `candidate/v0.1.0`.

Only users with push access can list Draft Releases through the GitHub API.
Because the repository is public, the temporary source tag itself is visible,
but its DMG assets remain in the Draft. The Draft must not be manually
published from the GitHub interface.

If acceptance fails, commit the fix to the same release branch and push again.
The workflow replaces the candidate assets and records the new commit in the
manifest. The old candidate must not be tagged as stable.

## Candidate acceptance checklist

Download the DMG from the Draft Release and verify at least:

- checksum matches the attached `.sha256` file;
- DMG opens and the app copies to `/Applications`;
- first-launch Gatekeeper instructions remain accurate;
- floating icon drag, expand direction, collapse position, and right-click
  Quit work;
- create, edit, complete, search, archive, and restore work;
- Chinese, English, system/light/dark themes, and Settings persistence work;
- relaunch preserves `~/.floatick` data;
- before the first stable release, manual update checks show the compact
  unavailable status instead of Sparkle's network error;
- after the first appcast is published, manual “Check for updates” opens
  Sparkle's native result;
- CPU and memory remain reasonable with a long todo list;
- both architecture slices exist, with an Apple silicon launch test and a
  Rosetta launch smoke test when available.

An in-app update smoke test additionally needs a genuine older build and newer
candidate build. Generate a signed test appcast, point a staging build at that
feed, and verify discovery, release notes, download, EdDSA validation,
replacement, relaunch, and data preservation. Also verify that a modified DMG
is rejected and a network failure leaves the installed app usable.

## Promote the accepted candidate

Open a pull request from `release/0.1.0` into `main` and use a merge commit.
Do not squash or rebase this release pull request: the accepted release-branch
commit must remain reachable from `main` so the tag can identify the exact
binary that was tested.

After the pull request is merged:

```bash
git fetch origin
candidate_sha=$(git rev-parse origin/release/0.1.0)
git merge-base --is-ancestor "$candidate_sha" origin/main
git tag -a v0.1.0 "$candidate_sha" -m "Floatick 0.1.0"
git push origin v0.1.0
```

Pushing the stable tag starts the Release workflow. Its preflight job has no
production secret and first checks the tag, Draft assets, checksum, manifest,
app version, and architectures. Only after those checks pass does the production
job wait for review. Open the workflow run, choose **Review deployments**,
select `production`, and click **Approve and deploy**. Self-approval remains
enabled because Floatick currently has one maintainer. The production Sparkle
secret is unavailable to the workflow until this approval.

After approval, the workflow fails safely unless:

- the tag is exactly `vMAJOR.MINOR.PATCH`;
- the tag matches the version in `pubspec.yaml`;
- the tagged commit is reachable from `main`;
- a Draft Release exists for the matching candidate;
- the stable tag and candidate tag resolve to the same commit;
- the attached manifest, checksum, app version, build number, and universal
  architectures all match.

The workflow does not rebuild the app. It signs an appcast for the accepted DMG,
renames and publishes the Draft Release, removes the temporary candidate tag,
and deploys the appcast to GitHub Pages. A rerun after a Pages failure reuses
the already published assets.

After a successful release, delete the release branch:

```bash
git push origin --delete release/0.1.0
git branch -d release/0.1.0
```

## Hotfixes

For a production-only hotfix, branch from the latest stable tag instead of
including unrelated unreleased work:

```bash
git switch -c release/0.1.1 v0.1.0
```

Apply the fix, increase both the public version and build number, and use the
same Draft → acceptance → merge commit → stable tag flow.

## Sparkle security

Sparkle is pinned to `2.9.2`. The update archive and appcast are signed with an
independent EdDSA key. The public key is stored in
`macos/Runner/Info.plist`; the private key is stored in the local login
Keychain and in the production environment's `SPARKLE_ED_PRIVATE_KEY` GitHub
Actions secret. Candidate workflows cannot access the production secret. The
production environment accepts only `v*` tags and requires approval from
`lucaslushuo` before exposing the secret.

Never commit or print the private key. Keep an encrypted offline backup. The
Sparkle key protects the update chain but does not replace Apple Developer ID
signing or notarization.

An old build without Sparkle cannot discover this update path. Users must
install the first Sparkle-enabled release manually once.

## Local unsigned package

For local layout testing only:

```bash
flutter build macos --release
tool/release/prepare_unsigned_app.sh \
  build/macos/Build/Products/Release/Floatick.app
tool/release/smoke_test_app.sh \
  build/macos/Build/Products/Release/Floatick.app
tool/release/create_dmg.sh \
  build/macos/Build/Products/Release/Floatick.app \
  build/release/Floatick-local.dmg \
  Floatick
```

An unsigned local DMG is not a public release candidate.
