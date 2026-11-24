# App Store listing

Listing texts, one file per language: `en.md` = primary language, English (U.S.); `es.md` =
Spanish (Spain); `ca.md` = Catalan. Paste each section into App Store Connect → SwimVibe → iOS
App → version page (name and subtitle are in **App Information**; add Spanish and Catalan with
the language menu at the top right). Limits: name 30, subtitle 30, promotional text 170, keywords
100 (comma-separated, no spaces after commas), description 4000. Check them with
`python3 store/app-store/check.py`.

## Screenshots

Four per language in `store/screenshots/ios/{en,es,ca}/`: 6.3" iPhone (1206×2622), the
**required** slot "iPhone with Dynamic Island (medium display)" (App Store Connect scales them for
the other iPhone sizes). Regenerate with
`flutter test store/screenshots/screenshots_test.dart --update-goldens`, then
`python3 store/screenshots/flatten_ios.py` (App Store Connect rejects transparency). The app is
iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad screenshots are needed.

## App Store Connect answers

**App Information**
- Category: primary **Health & Fitness**, secondary **Sports**.
- Content rights: no third-party content (the workouts are written by the developer).
- Age rating: answer **None/No** to every question (no violence, gambling, user-generated
  content, unrestricted web access or medical treatment info). Expected result: 4+.
- EU Digital Services Act: **non-trader** (same as InvestYoung).

**Pricing and Availability**
- Price: free (USD 0). Availability: all territories.

**App Privacy**
- Privacy policy URL: `https://alioli97.github.io/VibeSwim/privacy/`
- Data collection: **No, we do not collect data from this app.** (The workouts request carries
  no personal data; history, goal and favorites stay on the device.)

**Version page**
- Support URL: `https://alioli97.github.io/VibeSwim/support/`
- Marketing URL: `https://alioli97.github.io/VibeSwim/` (optional).
- Copyright: `2026 Arnau Alió Parull`
- Build: the latest TestFlight build (Actions → iOS → Run workflow).
- Export compliance: answered in `Info.plist` (`ITSAppUsesNonExemptEncryption = false`).

**App Review Information**
- Sign-in required: **no**.
- Contact: name, phone and email of the developer (private, only for Apple).
- Notes: paste `review-notes.txt` as is. For InvestYoung, App Review's first reply (guideline
  2.1, Information Needed) asked for a screen recording on a physical device from app launch,
  purpose and audience, setup, external services, regional differences and regulatory status:
  the notes answer all of them up front. Record the iPhone screen (Control Center → Screen
  Recording, about 2 minutes, following the order in the notes) and attach it in App Review.

**Version release**: manual or automatic after approval (developer's choice).
