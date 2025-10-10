import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'firebase_options.dart';
import 'telas/login.dart';
import 'telas/gestor/home_gestor.dart';
import 'telas/consultor/home_consultor.dart';

// Carrega o .env
Future<void> loadEnv() async {
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env carregado com sucesso');
  } catch (e) {
    print('❌ Falha ao carregar .env: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ 1. Iniciando app: WidgetsBinding OK');

  // ✅ Carrega o .env ANTES do Firebase
  await loadEnv();

  // ✅ Debug: mostra se as variáveis foram carregadas
  print('🔍 FIREBASE_PROJECT_ID: ${dotenv.get('FIREBASE_PROJECT_ID')}');
  print('🔍 FIREBASE_API_KEY_WEB: ${dotenv.get('FIREBASE_API_KEY_WEB')}');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ 2. Firebase inicializado com sucesso!');
  } catch (e, s) {
    print('❌ ERRO ao inicializar Firebase: $e');
    print('❌ Stack trace: $s');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Erro: $e\n\nVerifique:\n1. .env na raiz\n2. pubspec.yaml com assets: - .env\n3. web/index.html com Firebase JS',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
    return;
  }

  print('✅ 3. Executando MyApp...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ADEMICON Londrina',
      theme: theme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/gestor': (context) => const HomeGestor(),
        '/consultor': (context) => const HomeConsultor(),
      },
    );
  }
}
