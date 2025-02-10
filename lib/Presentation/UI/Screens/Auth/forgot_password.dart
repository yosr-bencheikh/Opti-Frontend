import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/code_verification.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class EnterEmailScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  EnterEmailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Enter your email"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                // Call the method (which returns void) and wait for completion.
                await authController.sendCodeToEmail(email);
                // If no error occurs, navigate to the code entry screen.
                Get.to(() => EnterCodeScreen(email: email));
              },
              child: Text("Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}
