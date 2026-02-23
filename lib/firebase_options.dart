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
        throw UnsupportedError('DefaultFirebaseOptions are not supported.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCkonucM_N5M9xKfCBIlP78rR3XKYkniyI",
    authDomain: "mas-mall.firebaseapp.com",
    projectId: "mas-mall",
    storageBucket: "mas-mall.firebasestorage.app",
    messagingSenderId: "932670079426",
    appId: "1:932670079426:web:249f99349401824c29165b",
    measurementId: "G-4KX8S82ZJ1",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7pSzsg9oMatHPt6CFhQS8jateTnLc5YA',
    appId: '1:932670079426:android:226ab3677fadb16329165b',
    messagingSenderId: '932670079426',
    projectId: 'mas-mall',
    storageBucket: 'mas-mall.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCkonucM_N5M9xKfCBIlP78rR3XKYkniyI",
    appId: '1:932670079426:ios:b13d30a3b4146c9629165b',
    messagingSenderId: '932670079426',
    projectId: 'mas-mall',
    storageBucket: 'mas-mall.firebasestorage.app',
    iosBundleId: 'com.example.msmall',
  );
}
