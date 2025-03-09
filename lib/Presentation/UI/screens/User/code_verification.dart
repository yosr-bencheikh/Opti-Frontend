import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/reset_password.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class EnterCodeScreen extends StatelessWidget {
  final String email;
  final TextEditingController codeController = TextEditingController();

  EnterCodeScreen({required this.email, super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: Text("Enter Verification Code")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "Enter your code"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                // Call the verify method and wait for it to complete.
                await authController.verifyCode(email, code);
                // If no error occurs, navigate to the reset password screen.
                Get.to(() => ResetPasswordScreen(email: email));
              },
              child: Text("Verify Code"),
            ),
          ],
        ),
      ),
    );
  }
}
