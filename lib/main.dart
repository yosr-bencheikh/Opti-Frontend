import 'package:flutter/material.dart';
import 'package:opti_app/presentation/UI/screens/auth/SignUpScreen.dart';
import 'package:opti_app/presentation/UI/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // L'écran de connexion est maintenant l'écran d'accueil
      routes: {
        '/signup': (context) => const SignUpScreen(),  // Route pour la page d'inscription
      },
    );
  }
}
