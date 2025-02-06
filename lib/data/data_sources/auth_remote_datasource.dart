import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<String> loginWithEmail(String email, String password);
  Future<String> loginWithGoogle(String token);
  Future<void> signUp(User user);
  Future<Map<String, dynamic>> getUser(String userId);
  Future<void> updateUser(String userId, Map<String, dynamic> userData);
  Future<void> sendCodeToEmail(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> resetPassword(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://127.0.0.1:3000/api';
  static String? verifiedEmail; // Made static
  static String? verificationCode;
  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<String> loginWithEmail(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        return responseData['token'];
      }
      throw ServerFailure(responseData['message'] ?? 'Login Failed');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<String> loginWithGoogle(String token) async {
    final url = Uri.parse('$baseUrl/google-login');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        return responseData['token'];
      }
      throw ServerFailure(responseData['message'] ?? 'Google Login Failed');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signUp(User user) async {
    final url = Uri.parse('$baseUrl/users');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': user.name,
          'prenom': user.prenom,
          'email': user.email,
          'date': user.date,
          'password': user.password,
          'phone': user.phone,
          'region': user.region,
          'gender': user.genre,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final responseData = json.decode(response.body);
        throw ServerFailure(responseData['message'] ?? 'Erreur d\'inscription');
      }
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> sendCodeToEmail(String email) async {
    final url = Uri.parse('http://localhost:3000/api/forgot-password');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw ServerFailure('Failed to send code');
    }
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load user');
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    final url = Uri.parse('$baseUrl/verify-code');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      print('Verify Code Response: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        verifiedEmail = email;
        verificationCode = code;
        print(
            'Verification State Set - Email: $verifiedEmail, Code: $verificationCode');
      } else {
        throw ServerFailure('Invalid or expired code');
      }
    } catch (e) {
      print('Verification Error: $e');
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email, String password) async {
    print('Reset Password - Current State:');
    print('Verified Email: $verifiedEmail');
    print('Verification Code: $verificationCode');
    print('Requested Email: $email');

    if (verifiedEmail != email) {
      throw ServerFailure('Please verify your code first');
    }

    final url = Uri.parse('$baseUrl/reset-password');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': password,
          'code': verificationCode,
        }),
      );

      print('Reset Password Response: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw ServerFailure(
            responseData['message'] ?? 'Failed to reset password');
      }

      verifiedEmail = null;
      verificationCode = null;
    } catch (e) {
      print('Reset Password Error: $e');
      throw ServerFailure(e.toString());
    }
  }
}
