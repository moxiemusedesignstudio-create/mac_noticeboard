import 'package:firebase_core/firebase_core.dart';
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

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCWt9MhmePSvzglKEgPHBgVbmIGZ-BTXfo',
    appId: '1:472677545818:web:caea530839e69d26d32563',
    messagingSenderId: '472677545818',
    projectId: 'mac-noticeboard',
    authDomain: 'mac-noticeboard.firebaseapp.com',
    storageBucket: 'mac-noticeboard.firebasestorage.app',
    measurementId: 'G-9689SNJGVQ',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBH-5QbG5sgyrvLCW3j9MDbm4UsLjub7Kk',
    appId: '1:31927910635:web:958ddc6eeab5f255d67eae',
    messagingSenderId: '31927910635',
    projectId: 'calendar-tracker-8280d',
    storageBucket: 'calendar-tracker-8280d.firebasestorage.app',
  );
}
