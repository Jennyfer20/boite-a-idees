import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBChvXBTngNfZ88--M2Ybu39lIkM3tJyD0',
    appId: '1:1032389854854:android:759d28f433a6a898467307',
    messagingSenderId: '1032389854854',
    projectId: 'boite-a-idees-f10f4',
    storageBucket: 'boite-a-idees-f10f4.firebasestorage.app',
  );
}
