import 'dart:io';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else {
      throw UnsupportedError(
          "playform error. not android or ios. DefaultFirebaseOption()");
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    //! WRITE YOUR OWN FIREBASE INFORMATION HERE.
    apiKey: 'AIzaSyA0Rchsnf43BX9EduLSCxQ-moc0rEUM1as',
    appId: '1:426363338745:android:59dbaab72c1f2de4358728',
    messagingSenderId: '426363338745',
    projectId: 'live-821fe',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    //! WRITE YOUR OWN FIREBASE INFORMATION HERE.
    apiKey: 'AIzaSyBL5NH_pBi_6DfoE7Rghki0i4QBG1AinJM',
    appId: '1:426363338745:ios:41818f7187edbcae358728',
    messagingSenderId: '426363338745',
    projectId: 'live-821fe',
  );
}
