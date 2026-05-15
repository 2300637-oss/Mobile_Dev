# Firebase Setup

The authentication module is implemented in Flutter, but this local workspace
does not contain your Firebase project credentials yet.

## Required Firebase Console Setup

1. Create or open a Firebase project.
2. Enable Authentication:
   - Open Firebase Console.
   - Select the `mobiledev-dee45` project.
   - Open Authentication.
   - Click Get started if this is the first time.
   - Open Sign-in method.
   - Enable Email/Password.
3. Create Android, iOS, and Web apps as needed.
4. Install the FlutterFire CLI if you have not already:

```powershell
dart pub global activate flutterfire_cli
```

5. Configure the app from the project root:

```powershell
flutterfire configure
```

This command should generate `lib/firebase_options.dart` and platform config
files such as `android/app/google-services.json`.

## Code Follow-Up

After `flutterfire configure`, update `lib/main.dart` to initialize Firebase
with the generated options:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

For Android, also follow any Gradle changes printed by the FlutterFire CLI.

## Current Android Firebase App

- Firebase project: `mobiledev-dee45`
- Android package name: `com.commissionapp.commission_app`

If registration shows `CONFIGURATION_NOT_FOUND`, Firebase Authentication has
not been started/enabled in Firebase Console for this project yet.
