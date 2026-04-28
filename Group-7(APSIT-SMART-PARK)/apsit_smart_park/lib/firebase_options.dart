// Firebase options for project: apsit-smart-park-31d03
// Project Number : 64688450202
// Android App ID : 1:64688450202:android:82bd0eff33ed0c9aca0d23
// Web / iOS App IDs below come from the Firebase console ─ update if you
// register additional platform apps.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        // Fall back to Android config on other platforms (desktop builds)
        return android;
    }
  }

  // ── Web ──────────────────────────────────────────────────────────────────
  // Register a Web app in the Firebase console and paste its appId here.
  // Until then the Android config is used as a safe fallback on web too.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBfdm_IUhkuFiVkc-Vra79ES9Cq55qu1NM',
    appId: '1:64688450202:web:82bd0eff33ed0c9aca0d23', // update with real web appId
    messagingSenderId: '64688450202',
    projectId: 'apsit-smart-park-31d03',
    authDomain: 'apsit-smart-park-31d03.firebaseapp.com',
    storageBucket: 'apsit-smart-park-31d03.appspot.com',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  // Matches google-services.json → client[0].client_info.mobilesdk_app_id
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfdm_IUhkuFiVkc-Vra79ES9Cq55qu1NM',
    appId: '1:64688450202:android:82bd0eff33ed0c9aca0d23',
    messagingSenderId: '64688450202',
    projectId: 'apsit-smart-park-31d03',
    storageBucket: 'apsit-smart-park-31d03.appspot.com',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  // Register an iOS app in the Firebase console, download GoogleService-Info.plist
  // and update the appId below with the GOOGLE_APP_ID value from that plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfdm_IUhkuFiVkc-Vra79ES9Cq55qu1NM',
    appId: '1:64688450202:ios:82bd0eff33ed0c9aca0d23', // update with real iOS appId
    messagingSenderId: '64688450202',
    projectId: 'apsit-smart-park-31d03',
    storageBucket: 'apsit-smart-park-31d03.appspot.com',
    iosClientId: '64688450202-jf55v5e4e6hhe2g5cn56uoudb96up5m7.apps.googleusercontent.com',
    iosBundleId: 'com.apsit.smartpark',
  );
}
