// File generated based on google-services.json configuration.
// DO NOT edit manually — re-run `flutterfire configure` to regenerate
// if you add iOS or web platforms later.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'College Bridge does not support web. '
        'Run `flutterfire configure` to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'No iOS configuration found. '
          'Add GoogleService-Info.plist and re-run `flutterfire configure`.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for desktop platforms.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcYKtv3d0JXa0tlcGbTlke5AVFHZgjuWg',
    appId: '1:784598194727:android:457cefb3c3a29d15c64c02',
    messagingSenderId: '784598194727',
    projectId: 'college-bridge-96f08',
    storageBucket: 'college-bridge-96f08.firebasestorage.app',
  );
}
