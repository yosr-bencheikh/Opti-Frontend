// lib/presentation/screens/enter_email_screen.dart
import 'package:flutter/material.dart';
import 'package:opti_app/Presentation/UI/screens/auth/code_verification.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
import 'package:opti_app/domain/usecases/send_code_to_email.dart';
import 'package:opti_app/domain/usecases/verify_code.dart';
import 'package:http/http.dart' as http;


class EnterEmailScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final SendCodeToEmail sendCodeToEmail;

EnterEmailScreen({
    Key? key,  
    required this.sendCodeToEmail,
  }) : super(key: key);

  
  @override
  Widget build(BuildContext context) {
    final authRemoteDataSource = AuthRemoteDataSourceImpl(client: http.Client()); // Move here
    final authRepository = AuthRepositoryImpl(authRemoteDataSource);

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
                final email = emailController.text;
                final result = await sendCodeToEmail(email);
                result.fold(
                  (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.toString())),
                  ),
                  (_) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnterCodeScreen(
                        email: email,
                        verifyCode: VerifyCode(authRepository),
                      ),
                    ),
                  ),
                );
              },
              child: Text("Send Code"),
            ),
          ],
        ),
      ),
    );
  }
}
