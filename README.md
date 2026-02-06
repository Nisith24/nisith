# NeetFlow Flutter

Flutter migration of the React Native MCQ learning app.

## Setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install/windows

2. Add Flutter to PATH

3. Configure Firebase:

   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure (use your existing Firebase project)
   flutterfire configure
   ```

   Or manually copy your `google-services.json` to `android/app/`

4. Install dependencies:

   ```bash
   flutter pub get
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── firebase_options.dart     # Firebase config
├── core/
│   ├── models/              # Data models (MCQ, QuestionPack, etc.)
│   ├── theme/               # App theme and colors
│   ├── router/              # GoRouter navigation
│   ├── storage/             # Hive local storage
│   └── utils/               # Constants, spring physics
└── features/
    ├── auth/                # Authentication
    ├── mcq/                 # MCQ deck and cards
    ├── learn/               # Flashcards, mock test config
    ├── exam/                # Test flow
    ├── bookmarks/           # Bookmark management
    ├── stats/               # Analytics
    ├── settings/            # Profile, settings
    └── shared/              # Floating nav, shared widgets
```

## Tech Stack

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Storage**: Hive
- **Backend**: Firebase (Auth, Firestore)
- **Networking**: Dio
