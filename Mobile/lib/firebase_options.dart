import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Função para carregar o .env e esperar
Future<void> loadEnv() async {
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env carregado com sucesso');
  } catch (e) {
    print('❌ Falha ao carregar .env: $e');
    // Não lança erro, mas avisa
  }
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isIOS) {
      return ios;
    } else if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError('Plataforma não suportada');
  }

  static FirebaseOptions get web {
    // Validação: evita retornar null
    return FirebaseOptions(
      apiKey: dotenv.get('FIREBASE_API_KEY_WEB', fallback: 'AIzaSy_invalid'),
      appId: dotenv.get('FIREBASE_APP_ID_WEB', fallback: '1:0:web:invalid'),
      messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '0'),
      projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: 'congestmobile'),
      authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: 'congestmobile.firebaseapp.com'),
      storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: 'congestmobile.appspot.com'),
    );
  }

  // Repita para android e ios (sem mudar)
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.get('FIREBASE_API_KEY_ANDROID', fallback: 'AIzaSy_invalid'),
        appId: dotenv.get('FIREBASE_APP_ID_ANDROID', fallback: '1:0:android:invalid'),
        messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '0'),
        projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: 'congestmobile'),
        storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: 'congestmobile.appspot.com'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.get('FIREBASE_API_KEY_IOS', fallback: 'AIzaSy_invalid'),
        appId: dotenv.get('FIREBASE_APP_ID_IOS', fallback: '1:0:ios:invalid'),
        messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '0'),
        projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: 'congestmobile'),
        storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: 'congestmobile.appspot.com'),
        iosClientId: dotenv.get('FIREBASE_IOS_CLIENT_ID', fallback: 'invalid.apps.googleusercontent.com'),
        iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID', fallback: 'br.com.ademicom.ConGestMobile'),
      );
}
