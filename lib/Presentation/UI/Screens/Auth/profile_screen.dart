import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Photo
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  "assets/profile_placeholder.png"), // Add an image to assets
            ),
            const SizedBox(height: 20),
            // Button 1 - Navigate to Page 1
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, '/updateProfile'); // Define routes in main.dart
              },
              child: const Text("update profile"),
            ),
            const SizedBox(height: 10),
            // Button 2 - Navigate to Page 2
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, '/page2'); // Define routes in main.dart
              },
              child: const Text("Go to Page 2"),
            ),
          ],
        ),
      ),
    );
  }
}
