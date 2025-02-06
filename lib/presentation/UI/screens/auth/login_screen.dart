import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:opti_app/Presentation/utils/validators.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
import 'package:opti_app/domain/usecases/login_with_email.dart';
import 'package:opti_app/domain/usecases/login_with_google.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
 const LoginScreen({Key? key}) : super(key: key);

 @override
 _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final TextEditingController emailController = TextEditingController();
 final TextEditingController passwordController = TextEditingController();
 final GoogleSignIn _googleSignIn = GoogleSignIn();
 bool _isLoading = false;

 late final LoginWithEmailUseCase _loginWithEmailUseCase;
 late final LoginWithGoogleUseCase _loginWithGoogleUseCase;

@override
void initState() {
  super.initState();
  final authRepository = AuthRepositoryImpl(AuthRemoteDataSourceImpl(client: http.Client()));
  _loginWithEmailUseCase = LoginWithEmailUseCase(authRepository);
  _loginWithGoogleUseCase = LoginWithGoogleUseCase(authRepository);
}


 Future<void> loginUser() async {
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  print("Email: $email");
  print("Password: $password");  // Debugging the password

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  if (!Validators.isValidEmail(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid email')),
    );
    return;
  }

  if (!Validators.isValidPassword(password)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password must be at least 8 characters long and contain both letters and numbers')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final token = await _loginWithEmailUseCase.execute(email, password);
    await _storeToken(token);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login Successful')),
    );
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

 Future<void> googleLogin() async {
   try {
     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
     if (googleUser == null) return;

     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
     
     final token = await _loginWithGoogleUseCase.execute(googleAuth.idToken!);
     await _storeToken(token);
     
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Google Login Successful')),
     );
     Navigator.pushReplacementNamed(context, '/home');
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(e.toString())),
     );
   }
 }

 Future<void> _storeToken(String token) async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('auth_token', token);
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Container(
       decoration: const BoxDecoration(
         gradient: LinearGradient(
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
           colors: [Colors.blueAccent, Colors.purpleAccent],
         ),
       ),
       child: Center(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16.0),
           child: Card(
             elevation: 8.0,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(16.0),
             ),
             child: Padding(
               padding: const EdgeInsets.all(24.0),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Text(
                     'Welcome Back!',
                     style: TextStyle(
                       fontSize: 28,
                       fontWeight: FontWeight.bold,
                       color: Colors.blue,
                     ),
                   ),
                   const SizedBox(height: 20),
                   const Text(
                     'Sign in to continue',
                     style: TextStyle(
                       fontSize: 16,
                       color: Colors.grey,
                     ),
                   ),
                   const SizedBox(height: 40),
                   TextField(
                     controller: emailController,
                     decoration: InputDecoration(
                       labelText: 'Email',
                       prefixIcon: const Icon(Icons.email, color: Colors.blue),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8.0),
                         borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                   TextField(
                     controller: passwordController,
                     obscureText: true,
                     decoration: InputDecoration(
                       labelText: 'Password',
                       prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8.0),
                         borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                       ),
                     ),
                   ),
                   const SizedBox(height: 30),
                   ElevatedButton(
                     onPressed: _isLoading ? null : loginUser,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                       backgroundColor: Colors.blue,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                     ),
                     child: _isLoading
                         ? const CircularProgressIndicator(color: Colors.white)
                         : const Text(
                             'Login',
                             style: TextStyle(fontSize: 18, color: Colors.white),
                           ),
                   ),
                   const SizedBox(height: 20),
                   TextButton(
                     onPressed: () {
                       Navigator.pushNamed(context, '/ForgotPasswordScreen');
                     },
                     child: const Text(
                       'Forgot Password?',
                       style: TextStyle(color: Colors.blue),
                     ),
                   ),
                   const SizedBox(height: 20),
                   ElevatedButton.icon(
                     onPressed: googleLogin,
                     icon: const Icon(Icons.login),
                     label: const Text('Login with Google'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.red,
                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8.0),
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                   TextButton(
                     onPressed: () {
                       Navigator.pushNamed(context, '/signup');
                     },
                     child: const Text(
                       'Don\'t have an account? Sign up',
                       style: TextStyle(color: Color.fromARGB(255, 22, 27, 32)),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     ),
   );
 }
}