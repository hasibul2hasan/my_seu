// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyIDxhgjrhKAlJEHNBs7FChEvTwMSANGo',
    appId: '1:1008929485587:android:f95b02810166c0e92420e6',
    messagingSenderId: '1008929485587',
    projectId: 'my-seu',
    storageBucket: 'my-seu.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9iuQPqNDDZslRRG73oahlf7MjCXe8P5M',
    appId: '1:1008929485587:ios:9fcfefa3905cfc7b2420e6',
    messagingSenderId: '1008929485587',
    projectId: 'my-seu',
    storageBucket: 'my-seu.firebasestorage.app',
    androidClientId: '1008929485587-cqr81jn59i2ia9o2p4ing0jf6jeevkoh.apps.googleusercontent.com',
    iosClientId: '1008929485587-p89d68e4rqtk0v224hf3b5j5vj8vckl3.apps.googleusercontent.com',
    iosBundleId: 'com.example.ums',
  );

}