# Release guide

## Application id

`com.alioli97.swimvibe` on both Android (application id) and iOS (bundle id), the same format
as InvestYoung (`com.alioli97.investyoung`).

**This id is final — do not change it.** Neither the App Store nor Google Play allow changing it
once the app is published: a new id is a different app.

## Versioning

`version` in `pubspec.yaml` is `name+build` (e.g. `1.0.0+1`). Bump the name for every release
(`1.0.1` for fixes, `1.1.0` for features). On iOS the build number is set by CI (see below), so
only the name matters there.

## iOS (App Store / TestFlight)

There is no local Mac: iOS builds run on GitHub Actions macOS runners (`.github/workflows/ios.yml`,
free because the repository is public). PRs that touch the iOS project and pushes to `master`
build the app unsigned. A signed build is uploaded to TestFlight by running the workflow by hand:
**Actions → iOS → Run workflow**.

The archive is signed automatically by Xcode through an App Store Connect API key; the export
re-signs it for distribution with the certificate and profile stored as secrets (never in the
repository). The pipeline is the one already used for InvestYoung (same Apple Developer team).

### One-time setup

Reused from InvestYoung (same team), nothing new to create:

- The registered device (automatic signing needs one to issue the development profile used at
  archive time).
- The App Store Connect API key (Admin role) and the team id.
- The Apple Distribution certificate (`~/ios-signing/dist.p12`, expires 2027-11-21).

New for SwimVibe:

1. Register the bundle id `com.alioli97.swimvibe` (Certificates, IDs & Profiles → Identifiers),
   with no extra capabilities.
2. Create the app in App Store Connect with that bundle id (name "SwimVibe", primary language
   to choose there, SKU e.g. `swimvibe`).
3. Profiles → + → **App Store Connect**, bundle id `com.alioli97.swimvibe`, the existing Apple
   Distribution certificate; download the `.mobileprovision`.
4. Store the GitHub secrets in **this** repository (alioli97/VibeSwim → Settings → Secrets and
   variables → Actions), with the same values as in InvestYoung except the profile:
   - `APPSTORE_API_KEY` (contents of the `.p8`), `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`,
     `APPLE_TEAM_ID`;
   - `IOS_DIST_P12_BASE64` (`base64 -w0 ~/ios-signing/dist.p12`) and `IOS_DIST_P12_PASSWORD`;
   - `IOS_APPSTORE_PROFILE_BASE64`: `base64 -w0` of the **new** SwimVibe profile.

   With the GitHub CLI, from the repository folder (each command asks for the value or reads the
   file):

   ```bash
   gh secret set APPSTORE_API_KEY < /path/to/AuthKey_XXXXXXXXXX.p8
   gh secret set APPSTORE_KEY_ID
   gh secret set APPSTORE_ISSUER_ID
   gh secret set APPLE_TEAM_ID
   base64 -w0 ~/ios-signing/dist.p12 | gh secret set IOS_DIST_P12_BASE64
   gh secret set IOS_DIST_P12_PASSWORD
   base64 -w0 /path/to/SwimVibe_AppStore.mobileprovision | gh secret set IOS_APPSTORE_PROFILE_BASE64
   ```

Apple's cloud-managed distribution signing cannot be used with this account: it writes the
accented name of the certificate ("Alió") in a different Unicode form than the certificate
itself, and App Store Connect rejects the upload (ITMS-90035). That is why the export signs on
the runner with our own certificate.

The certificate and the profile expire after one year: renew them and update the secrets (in
both repositories for the certificate).

### Uploading a build

Actions → iOS → Run workflow (branch `master`). The version name comes from `pubspec.yaml`; the
build number is `100 + run number` of the workflow, so every upload gets a new one. After the
upload, Apple processes the build (roughly 10–30 minutes) before it shows up in TestFlight.

### App settings in the project

- iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait only, so no iPad screenshots are needed.
- Display name "SwimVibe"; languages declared: English, Spanish and Catalan
  (`ios/Runner/{en,es,ca}.lproj/InfoPlist.strings`, checked by the unsigned CI build).
- Export compliance answered in `Info.plist` (`ITSAppUsesNonExemptEncryption = false`): the app
  only uses standard HTTPS to read workouts from Supabase.
- Icon: generated from `assets/icon/icon.png` without transparency (`remove_alpha_ios`).
