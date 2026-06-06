// lib/firebase_options.dart
// Values are injected at build time via --dart-define flags (see CI workflow).
// For local dev: replace String.fromEnvironment(...) with your actual values
// OR run `flutterfire configure` to auto-generate this file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            String.fromEnvironment('FIREBASE_API_KEY'),
    appId:             String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:         String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket:     String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            String.fromEnvironment('FIREBASE_API_KEY'),
    appId:             String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:         String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket:     String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosClientId:       String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    iosBundleId:       'com.marnie.pos',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            String.fromEnvironment('FIREBASE_API_KEY'),
    appId:             String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId:         String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket:     String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    authDomain:        String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    measurementId:     String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
  );
}
