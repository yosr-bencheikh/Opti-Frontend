import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/Screens/Auth/reset_password.dart';
import 'dart:convert';
// Import the reset password screen

class EnterCodeScreen extends StatefulWidget {
  final String email; // The email will be passed from the previous screen

  EnterCodeScreen({required this.email});

  @override
  _EnterCodeScreenState createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final TextEditingController codeController = TextEditingController();

  Future<void> verifyCode() async {
    final code = codeController.text;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please enter the code")));
      return;
    }

    final url = Uri.parse(
        'http://localhost:3000/api/verify-code'); // Replace with your backend URL
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
          {'email': widget.email, 'code': code}), // Use the passed email here
    );

    if (response.statusCode == 200) {
      // Code is verified, navigate to reset password screen
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Code verified!")));

      // Navigate to the reset password screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
      );
    } else {
      final responseBody = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(responseBody['message'] ?? "Invalid or expired code")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: verifyCode,
              child: Text("Verify Code"),
            ),
          ],
        ),
      ),
    );
  }
}
