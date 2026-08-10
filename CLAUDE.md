# Claude Handoff

Build the DCN Admin mobile app in Flutter. This is a fresh mobile-only rebuild; do not recreate the old web app and do not generate Flutter web unless explicitly requested.

Read the full implementation brief first:

- `docs/product-brief-for-claude.md`

Important constraints:

- Use the configured Firebase project `dcnchurchadmin` as the main backend.
- Android package and iOS bundle ID are both `com.dcnchurchadmin.dcnadmin`.
- Firebase is already configured through FlutterFire in `lib/firebase_options.dart`.
- Existing DCN visual assets are in `assets/branding/`.
- Do not use prototype/demo data in production flows.
- Signup must fetch real departments, sub-units, inviter workers, invite-code validation, and account submission data from the backend.
- Login must authenticate against real backend credentials, then route by the returned user role/persona.
- Signup does not log the user in immediately; it submits an application and shows an approval-pending state.

Run these checks before handing work back:

```sh
flutter analyze
flutter test
flutter build apk --debug
```
