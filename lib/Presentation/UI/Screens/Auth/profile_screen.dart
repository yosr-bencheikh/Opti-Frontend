import 'package:flutter/material.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve the user ID passed from the LoginScreen
     final userId = ModalRoute.of(context)?.settings.arguments as String??' ';

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome User $userId'),
            ElevatedButton(
              onPressed: () {
                // Pass the user ID to the update profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfileScreen(userId: userId),
                  ),
                );
              },
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
