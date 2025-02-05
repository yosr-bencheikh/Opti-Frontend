import 'package:flutter/material.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/admin_panel.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/forgot_password.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/profile_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/update_profile_screen.dart';
import 'Presentation/UI/Screens/Auth/profile_screen.dart'; // Import the Profile Screen
import 'package:opti_app/Presentation/UI/screens/auth/SignUpScreen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_screen.dart';

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
      home: 
       LoginScreen(), // Profile screen is the first screen
      routes: {
        '/profileScreen': (context) => const ProfileScreen(),
        '/dashboard': (context) => AdminPanelApp (),
        '/ForgotPasswordScreen': (context) => EnterEmailScreen(),
        '/updateProfile': (context) => const UpdateProfileScreen(
              userId: '67a0cb53c575bdaa95c3421f',
            ),
        '/signup': (context) => const SignUpScreen(),
      }, // Set ProfileScreen as the first screen
      debugShowCheckedModeBanner: false, // Removes the debug banner
    );
  }
}
