// Firebase configuration for project: yonsei-simple
// Generated from google-services.json (Android) + Web firebaseConfig

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5AMP7DgJuWNuE8lQy-AawbMMEtAIMTJ4',
    appId: '1:1000419289778:web:5531cc300c8927fb6437ab',
    messagingSenderId: '1000419289778',
    projectId: 'yonsei-simple',
    authDomain: 'yonsei-simple.firebaseapp.com',
    storageBucket: 'yonsei-simple.firebasestorage.app',
    measurementId: 'G-403S0JBNZ1',
  );

  // ── Android ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZep55Y-m5HixE8nuiRfmskFRNXRnNAoQ',
    appId: '1:1000419289778:android:8396e896cce844a06437ab',
    messagingSenderId: '1000419289778',
    projectId: 'yonsei-simple',
    authDomain: 'yonsei-simple.firebaseapp.com',
    storageBucket: 'yonsei-simple.firebasestorage.app',
  );
}
