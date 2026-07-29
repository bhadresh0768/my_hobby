# Project Setup Guide

Follow these steps to set up the development environment for ShopFinder.

## 1. Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version specified in `pubspec.yaml`)
*   [Dart SDK](https://dart.dev/get-started/sdk)
*   Android Studio / VS Code
*   A Firebase Project

## 2. Firebase Configuration
The app requires a Firebase connection to function.
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project named `ShopFinder`.
3.  Add an **Android App**:
    *   Package name: `com.example.my_hobby` (check `android/app/build.gradle`)
    *   Download `google-services.json` and place it in `android/app/`.
4.  Add an **iOS App**:
    *   Bundle ID: `com.example.myHobby`
    *   Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
5.  Enable **Authentication**:
    *   Enable Email/Password and Anonymous providers.
6.  Enable **Cloud Firestore**:
    *   Start in test mode or apply the rules defined in `DATABASE.md`.
7.  Enable **Cloud Storage**.

## 3. Environment Secrets
Create a `.env` file (if applicable) or update `lib/core/app_constants.dart` with your specific API keys:
*   **AdMob IDs**: Update Android/iOS App IDs in `AndroidManifest.xml` and `Info.plist`.
*   **Google Maps API Key**: Add to `AndroidManifest.xml` and `AppDelegate.swift`.

## 4. Running the App
```bash
# Get dependencies
flutter pub get

# Generate Localization files (if not automatic)
flutter gen-l10n

# Run on a connected device
flutter run
```

## 5. Troubleshooting
*   **Missing `firebase_options.dart`**: Run `flutterfire configure` if you have the FlutterFire CLI installed.
*   **CocoaPods errors (iOS)**: Run `cd ios && pod install && cd ..`.
*   **AdMob errors**: Ensure you have configured the correct `APPLICATION_ID` in the platform-specific files.
