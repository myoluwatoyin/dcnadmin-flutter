# DCN Admin Flutter

Fresh Flutter mobile app scaffold for the DCN Admin project.

## Project Setup

- Flutter project name: `dcnadmin`
- Local folder: `/Users/mac/development/dcnadmin-flutter`
- GitHub repo: `https://github.com/myoluwatoyin/dcnadmin-flutter`
- Firebase project: `dcnchurchadmin`
- Firebase account used by CLI: `ictsolutionsomega@gmail.com`
- Android package: `com.dcnchurchadmin.dcnadmin`
- iOS bundle ID: `com.dcnchurchadmin.dcnadmin`

This scaffold intentionally includes only Flutter mobile platforms:

- Android
- iOS

No Flutter web platform was generated.

## Firebase

FlutterFire has generated:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `firebase.json`
- `.firebaserc`

Registered Firebase apps:

- Android: `1:961146804705:android:1d00bbe390c348ce9a9aa0`
- iOS: `1:961146804705:ios:e13d550e4e2edb149a9aa0`

Installed Firebase packages:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `firebase_messaging`

The app already calls `Firebase.initializeApp` in `lib/main.dart`.

## Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

To refresh Firebase configuration later:

```sh
flutterfire configure \
  --project=dcnchurchadmin \
  --platforms=android,ios \
  --android-package-name=com.dcnchurchadmin.dcnadmin \
  --ios-bundle-id=com.dcnchurchadmin.dcnadmin
```
