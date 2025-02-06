import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/auth/SignUpScreen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/admin_panel.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/profile_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/update_profile_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/forgot_password.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart'; // Import AuthRemoteDataSource
import 'package:opti_app/domain/repositories/auth_repository_impl.dart'; // Import AuthRepositoryImpl
import 'package:opti_app/domain/usecases/send_code_to_email.dart'; // Import SendCodeToEmail
import 'package:opti_app/domain/repositories/auth_repository.dart'; // Import AuthRepository

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate http.Client
    final httpClient = http.Client();

    // Instantiate AuthRemoteDataSource
    final authRemoteDataSource = AuthRemoteDataSourceImpl(client: httpClient);

    // Instantiate AuthRepositoryImpl with AuthRemoteDataSource
    final authRepository = AuthRepositoryImpl(authRemoteDataSource);

    // Instantiate SendCodeToEmail use case
    final sendCodeToEmail = SendCodeToEmail(authRepository);

    return MaterialApp(
      title: 'Opti App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/profileScreen': (context) =>  ProfileScreen(),
        '/dashboard': (context) => AdminPanelApp(),
        '/ForgotPasswordScreen': (context) => EnterEmailScreen(sendCodeToEmail: sendCodeToEmail),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
