import 'package:flutter/material.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/profile_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/update_profile_screen.dart';
import 'Presentation/UI/Screens/Auth/profile_screen.dart'; // Import the Profile Screen

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
      initialRoute: '/',  // Profile screen is the first screen
      routes: {
        '/': (context) => const ProfileScreen(),
        '/updateProfile': (context) => const UpdateProfileScreen(userId:'67a09a82c575bdaa95c3421d',),
      }, // Set ProfileScreen as the first screen
      debugShowCheckedModeBanner: false, // Removes the debug banner
    );
  }
}
