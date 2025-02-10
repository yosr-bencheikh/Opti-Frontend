import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<String> loginWithEmail(String email, String password);
  Future<String> loginWithGoogle(String token);
  Future<String> loginWithFacebook(String accessToken);
  Future<Map<String, dynamic>> signUp(User user);
  Future<Map<String, dynamic>> getUser(String userId);
  Future<void> updateUser(String userId, User userData);
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
        // Login successful, return the token
        return responseData['token'];
      } else if (response.statusCode == 404) {
        // Handle specific error messages returned by the backend
        String errorMessage = responseData['message'] ?? 'Login Failed';
        if (errorMessage == 'Email not found') {
          throw Exception('Email not found. Please check your email address.');
        } else if (errorMessage == 'Incorrect password') {
          throw Exception('Incorrect password. Please try again.');
        } else {
          throw Exception(errorMessage);
        }
      } else {
        // For other status codes, throw a general server failure
        throw Exception(
            'Server failure: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Catch any error (network or other)
      throw Exception('An error occurred: ${e.toString()}');
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
  Future<Map<String, dynamic>> signUp(User user) async {
    final url = Uri.parse('$baseUrl/users');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': user.nom,
          'prenom': user.prenom,
          'email': user.email,
          'date': user.date,
          'password': user.password,
          'phone': user.phone,
          'region': user.region,
          'genre': user.genre,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print("SignUp response data: $data");
        if (data.containsKey('token')) {
          return data;
        } else {
          throw Exception('Missing  token in response');
        }
      }
      throw Exception('Failed to sign up: ${response.body}');
    } catch (e) {
      throw Exception('Error in signUp: $e');
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
    final url = '$baseUrl/users/$userId';
    debugPrint('Calling URL: $url');
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to load user';
      throw Exception('HTTP ${response.statusCode}: $errorMessage');
    }
  }

  Future<void> updateUser(String userId, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user),
    );
    if (response.statusCode == 200) {
      print('Profile updated successfully');
    } else {
      // Log the error response
      final errorResponse = json.decode(response.body);
      throw Exception('Failed to update user: ${errorResponse['message']}');
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

  Future<String> loginWithFacebook(String accessToken) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/facebook-login'),
        body: {'accessToken': accessToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['token'];
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
