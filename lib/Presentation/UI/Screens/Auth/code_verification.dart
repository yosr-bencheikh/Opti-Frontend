import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:opti_app/Presentation/UI/screens/auth/reset_password.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/usecases/reset_password.dart';
import 'package:opti_app/domain/usecases/verify_code.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';

class EnterCodeScreen extends StatelessWidget {
  final String email;
  final TextEditingController codeController = TextEditingController();
  final VerifyCode verifyCode;

  final AuthRepository authRepository;

  // Constructor now initializes the authRepository
  EnterCodeScreen({required this.email, required this.verifyCode})
      : authRepository = AuthRepositoryImpl(
          AuthRemoteDataSourceImpl(client: http.Client()), // Initialize here
        );

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
              onPressed: () async {
                final code = codeController.text;
                final result = await verifyCode(email, code);
                result.fold(
                  (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.toString())),
                  ),
                  (_) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(
                        email: email,
                        resetPassword: ResetPassword(authRepository),
                      ),
                    ),
                  ),
                );
              },
              child: Text("Verify Code"),
            ),
          ],
        ),
      ),
    );
  }
}
