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
      case TargetPlatform.iOS:  
        throw UnsupportedError(  
          'DefaultFirebaseOptions have not been configured for ios - '  
          'you can reconfigure this by running the FlutterFire CLI again.',  
        );  
      default:  
        throw UnsupportedError(  
          'DefaultFirebaseOptions are not supported for this platform.',  
        );  
    }  
  }  

  static const FirebaseOptions android = FirebaseOptions(  
    apiKey: 'AIzaSyD2-wg6y1ZRI-1uQDapqFl4OsHk9_NIuCs',  
    appId: '1:578128749767:android:6d76cf7bf28af5ddee8ae2',  
    messagingSenderId: '578128749767',  
    projectId: 'amir-bistro-orders-34a59',  
    storageBucket: 'amir-bistro-orders-34a59.firebasestorage.app',  
  );  

  static const FirebaseOptions web = FirebaseOptions(  
    apiKey: 'AIzaSyD2-wg6y1ZRI-1uQDapqFl4OsHk9_NIuCs',  
    appId: '1:578128749767:web:6d76cf7bf28af5ddee8ae2',  
    messagingSenderId: '578128749767',  
    projectId: 'amir-bistro-orders-34a59',  
    authDomain: 'amir-bistro-orders-34a59.firebaseapp.com',  
    storageBucket: 'amir-bistro-orders-34a59.firebasestorage.app',  
  );  
}  