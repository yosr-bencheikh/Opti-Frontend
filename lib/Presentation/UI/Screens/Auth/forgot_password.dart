import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:opti_app/Presentation/UI/Screens/Auth/code_verification.dart';

class EnterEmailScreen extends StatefulWidget {
  @override
  _EnterEmailScreenState createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final TextEditingController emailController = TextEditingController();

  // Method to send the email and get the verification code
  Future<void> sendCodeToEmail() async {
    final email = emailController.text;

    // Make sure email is not empty
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please enter an email")));
      return;
    }

    final url = Uri.parse(
        'http://localhost:3000/api/forgot-password'); // Replace with your backend URL
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        // On success, navigate to the next screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnterCodeScreen(email: emailController.text),
          ),
        );
      } else {
        // Handle error responses with specific error messages
        final responseBody = json.decode(response.body);
        String errorMessage = "Error sending verification code";

        // Handle different error scenarios more specifically
        switch (response.statusCode) {
          case 400:
            errorMessage = responseBody['message'] ??
                "Bad request: Invalid email or data format.";
            break;
          case 404:
            errorMessage = responseBody['message'] ??
                "User not found. Please check your email.";
            break;
          case 500:
            errorMessage = responseBody['message'] ??
                "Server error. Please try again later.";
            break;
          case 401:
            errorMessage = responseBody['message'] ??
                "Unauthorized access. Please try again.";
            break;
          default:
            errorMessage = responseBody['message'] ??
                "Unknown error occurred. Please try again.";
            break;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      // Handle connection issues or other errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Error: Unable to connect to the server. Please check your internet connection."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: sendCodeToEmail,
              child: Text("Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}
