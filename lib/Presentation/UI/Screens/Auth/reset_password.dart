import 'package:flutter/material.dart';
import 'package:opti_app/domain/usecases/reset_password.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final ResetPassword resetPassword;

  ResetPasswordScreen({required this.email, required this.resetPassword});

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

    try {
      final result = await widget.resetPassword(widget.email, password);
      
      result.fold(
        (failure) => _showError(failure.toString()),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password reset successfully")),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}