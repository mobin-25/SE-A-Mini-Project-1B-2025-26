// Firebase configuration for MySociety app
// Project: my-society-yfj8us
// Generated from google-services.json credentials

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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC17goZ6hjEvEbphjeDUR_fmiN-Y3OT8Us',
    appId: '1:359795688863:android:4331da58ade94d2b4a29aa',
    messagingSenderId: '359795688863',
    projectId: 'my-society-yfj8us',
    authDomain: 'my-society-yfj8us.firebaseapp.com',
    storageBucket: 'my-society-yfj8us.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC17goZ6hjEvEbphjeDUR_fmiN-Y3OT8Us',
    appId: '1:359795688863:android:4331da58ade94d2b4a29aa',
    messagingSenderId: '359795688863',
    projectId: 'my-society-yfj8us',
    storageBucket: 'my-society-yfj8us.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC17goZ6hjEvEbphjeDUR_fmiN-Y3OT8Us',
    appId: '1:359795688863:android:4331da58ade94d2b4a29aa',
    messagingSenderId: '359795688863',
    projectId: 'my-society-yfj8us',
    storageBucket: 'my-society-yfj8us.firebasestorage.app',
    iosBundleId: 'com.mycompany.mysociety',
  );
}
