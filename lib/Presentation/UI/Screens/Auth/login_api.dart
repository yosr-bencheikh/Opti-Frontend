import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package to your pubspec.yaml

class LoginApi {
  static final storage = FlutterSecureStorage();
  
  // Initialize GoogleSignIn
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: "95644263598-p1ko0g4ds7ko6v6obqkdc38j76ndjmt2.apps.googleusercontent.com",
  );

  static Future<Map<String, dynamic>?> login() async {
    try {
      // Sign out first to force account selection
      await _googleSignIn.signOut(); // Ensure no cached account is used

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign-in cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Debug logs
      print('Google Auth Token: ${googleAuth.idToken?.substring(0, 20)}...');

      // Send token to backend
      final response = await http.post(
        Uri.parse('https://7d38-197-21-236-218.ngrok-free.app/auth/google/callback'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'idToken': googleAuth.idToken, 'email': googleUser.email}),
      );

      // Debug logs
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await storage.write(key: 'jwt_token', value: responseData['token']);
        
        // Decode JWT token to get user ID
        final token = responseData['token'];
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['userId']; // Ensure your backend includes userId in JWT
        
        // Navigate to profile screen with user ID
        Get.offAllNamed('/profileScreen', arguments: userId);
        return responseData;
      } else {
        throw Exception('Authentication failed: ${response.body}');
      }
    } catch (error) {
      print('Google login error: $error');
      Get.snackbar(
        'Error',
        'Failed to connect with Google',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// 🔹 Connexion avec Facebook
 static Future<Map<String, dynamic>?> loginWithFacebook() async {
  try {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      final response = await http.post(
        Uri.parse('https://b88a-41-62-25-218.ngrok-free.app/auth/facebook/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': accessToken.tokenString,
          'email': userData['email'],
        }),
      );

      if (response.statusCode == 200) {
         final responseData = json.decode(response.body);
        await storage.write(key: 'jwt_token', value: responseData['token']);
        // Decode JWT token to get user ID
        final token = responseData['token'];
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['userId'];
        print('Facebook login successful: ${response.body}');
        Get.offAllNamed('/profileScreen', arguments: userId); // Navigate to profile after successful login
        return userData;
      } else {
        print('Facebook login server error: ${response.statusCode} - ${response.body}');
      }
    } else {
      print('Facebook sign-in cancelled or error: ${result.status}');
    }
  } catch (error) {
    print('Facebook login error: $error');
  }
  return null;
}
}
