import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated with your provided Firebase configuration.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDk4J0nrpo3BxAX8WVQvzXZ41JWm6-TjjA',
    appId: '1:691969576407:web:ac84b4f87f80aa5ee74f92',
    messagingSenderId: '691969576407',
    projectId: 'skillswap-e63ca',
    authDomain: 'skillswap-e63ca.firebaseapp.com',
    storageBucket: 'skillswap-e63ca.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk4J0nrpo3BxAX8WVQvzXZ41JWm6-TjjA',
    appId: '1:691969576407:web:ac84b4f87f80aa5ee74f92',
    messagingSenderId: '691969576407',
    projectId: 'skillswap-e63ca',
    authDomain: 'skillswap-e63ca.firebaseapp.com',
    storageBucket: 'skillswap-e63ca.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDk4J0nrpo3BxAX8WVQvzXZ41JWm6-TjjA',
    appId: '1:691969576407:web:ac84b4f87f80aa5ee74f92',
    messagingSenderId: '691969576407',
    projectId: 'skillswap-e63ca',
    authDomain: 'skillswap-e63ca.firebaseapp.com',
    storageBucket: 'skillswap-e63ca.firebasestorage.app',
  );
}
