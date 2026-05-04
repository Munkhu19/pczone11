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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCV4TtqGRZUO4RFNjeLy-srNn1_FtAeV08',
    appId: '1:175694151955:web:2664bacee52576b23adae6',
    messagingSenderId: '175694151955',
    projectId: 'esport-center-46cde',
    authDomain: 'esport-center-46cde.firebaseapp.com',
    storageBucket: 'esport-center-46cde.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8WgK0hmwSZWiJPO4UvRnJSlj-xqNN6ng',
    appId: '1:175694151955:android:09837977656f05413adae6',
    messagingSenderId: '175694151955',
    projectId: 'esport-center-46cde',
    storageBucket: 'esport-center-46cde.firebasestorage.app',
  );
}
