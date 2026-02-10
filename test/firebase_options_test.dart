import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neetflow_flutter/firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('DefaultFirebaseOptions.android uses values from dotenv', () {
    // Mock dotenv values
    dotenv.testLoad(fileInput: '''
FIREBASE_ANDROID_API_KEY=test_api_key
FIREBASE_ANDROID_APP_ID=test_app_id
FIREBASE_ANDROID_MESSAGING_SENDER_ID=test_sender_id
FIREBASE_ANDROID_PROJECT_ID=test_project_id
FIREBASE_ANDROID_STORAGE_BUCKET=test_bucket
''');

    // Check if values are correctly mapped
    final options = DefaultFirebaseOptions.android;

    expect(options.apiKey, 'test_api_key');
    expect(options.appId, 'test_app_id');
    expect(options.messagingSenderId, 'test_sender_id');
    expect(options.projectId, 'test_project_id');
    expect(options.storageBucket, 'test_bucket');
  });

  test('DefaultFirebaseOptions.currentPlatform throws for non-android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(() => DefaultFirebaseOptions.currentPlatform, throwsUnsupportedError);
    debugDefaultTargetPlatformOverride = null;
  });

   // We can't easily test currentPlatform for Android because it might be the default or hard to set in pure unit test without binding,
   // but we can try setting debugDefaultTargetPlatformOverride = TargetPlatform.android

  test('DefaultFirebaseOptions.currentPlatform returns android options on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

     dotenv.testLoad(fileInput: '''
FIREBASE_ANDROID_API_KEY=test_api_key
FIREBASE_ANDROID_APP_ID=test_app_id
FIREBASE_ANDROID_MESSAGING_SENDER_ID=test_sender_id
FIREBASE_ANDROID_PROJECT_ID=test_project_id
FIREBASE_ANDROID_STORAGE_BUCKET=test_bucket
''');

    final options = DefaultFirebaseOptions.currentPlatform;
    expect(options.apiKey, 'test_api_key');

    debugDefaultTargetPlatformOverride = null;
  });
}
