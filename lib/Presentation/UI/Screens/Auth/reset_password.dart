import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email, Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

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
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),
              obscureText: obscurePassword,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                ),
              ),
              obscureText: obscureConfirmPassword,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleResetPassword,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Reset Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters long");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);
    final AuthController authController = Get.find<AuthController>();

    // Call the resetPassword method and wait for it to complete.
    await authController.resetPassword(widget.email, password);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Password reset successfully")),
    );
    // Navigate to the login or home screen as appropriate.
    Get.offAllNamed('/');
    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
