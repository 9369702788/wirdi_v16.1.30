// File generated from google-services.json
// Equivalent to what `flutterfire configure` produces.
// DO NOT commit this file to a public repository.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android; // fallback
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyCgURUM3-OW6NBUEK66dmbQ7p0aywOFb8w',
    appId:             '1:391561027779:android:a52f7194b0134a22b30276',
    messagingSenderId: '391561027779',
    projectId:         'wirdi-cb813',
    storageBucket:     'wirdi-cb813.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyCgURUM3-OW6NBUEK66dmbQ7p0aywOFb8w',
    appId:             '1:391561027779:android:a52f7194b0134a22b30276',
    messagingSenderId: '391561027779',
    projectId:         'wirdi-cb813',
    storageBucket:     'wirdi-cb813.firebasestorage.app',
    iosClientId:       '', // add from a real GoogleService-Info.plist before shipping iOS
    iosBundleId:       'com.wirdi.wirdi',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyCgURUM3-OW6NBUEK66dmbQ7p0aywOFb8w',
    appId:             '1:391561027779:android:a52f7194b0134a22b30276',
    messagingSenderId: '391561027779',
    projectId:         'wirdi-cb813',
    storageBucket:     'wirdi-cb813.firebasestorage.app',
    authDomain:        'wirdi-cb813.firebaseapp.com',
  );
}
