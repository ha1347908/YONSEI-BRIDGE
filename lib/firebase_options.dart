import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDfChGwmugWj6WdUb4qcEcsw_FiHIs-JRY',
    appId: '1:764894318156:web:569bcd086379bcac236ee9',
    messagingSenderId: '764894318156',
    projectId: 'yonsei-bridge',
    authDomain: 'yonsei-bridge.firebaseapp.com',
    storageBucket: 'yonsei-bridge.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfChGwmugWj6WdUb4qcEcsw_FiHIs-JRY',
    appId: '1:764894318156:android:569bcd086379bcac236ee9',
    messagingSenderId: '764894318156',
    projectId: 'yonsei-bridge',
    authDomain: 'yonsei-bridge.firebaseapp.com',
    storageBucket: 'yonsei-bridge.firebasestorage.app',
  );
}
