// lib/presentation/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:opti_app/domain/usecases/reset_password.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ResetPassword resetPassword;

  ResetPasswordScreen({required this.email, required this.resetPassword});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text == confirmPasswordController.text) {
                  final result = await resetPassword(email, passwordController.text);
                  result.fold(
                    (failure) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.toString())),
                    ),
                    (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Password Reset Successfully!")),
                      );
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Passwords do not match!")),
                  );
                }
              },
              child: Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}