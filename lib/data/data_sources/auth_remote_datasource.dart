import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/user.dart';

/// The abstract class defining all authentication-related API calls.
abstract class AuthRemoteDataSource {
  Future<String> loginWithEmail(String email, String password);
  Future<Map<String, dynamic>> signUp(User user);
  Future<Map<String, dynamic>> getUser(String userId);
  Future<void> updateUser(String userId, User userData);
  Future<void> sendCodeToEmail(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> resetPassword(String email, String password);
  Future<String> uploadImage(String filePath, String userId);
  Future<void> updateUserImage(
      String userId, String imageUrl); // <-- New method
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  // Use your server's IP and port (make sure this is accessible from your phone)
  final String baseUrl = 'http://192.168.1.18:3000/api';


  
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
        body: json.encode({'email': email, 'password': password}),
      );
      print('Response status: ${response.statusCode}'); // Log response status
      print('Response body: ${response.body}');
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['token'] != null) {
        return responseData['token'];
      } else if (response.statusCode == 404) {
        String errorMessage = responseData['message'] ?? 'Login Failed';
        if (errorMessage == 'Email not found') {
          throw Exception('Email not found. Please check your email address.');
        } else if (errorMessage == 'Incorrect password') {
          throw Exception('Incorrect password. Please try again.');
        } else {
          throw Exception(errorMessage);
        }
      } else {
        throw Exception(
            'Server failure: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  @override

  Future<String> loginWithGoogle(String token) async {
    final url = Uri.parse('https://abc123.ngrok.io/auth/google/callback');

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
      print('Response status: ${response.statusCode}'); // Log response status
      print('Response body: ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('token')) {
          return data;
        } else {
          throw Exception('Missing token in response');
        }
      }
      throw Exception('Failed to sign up: ${response.body}');
    } catch (e) {
      throw Exception('Error in signUp: $e');
    }
  }

 @override
  Future<Map<String, dynamic>> getUser(String userId) async {
  final url = Uri.parse('$baseUrl/users/$userId');
  print('Full URL being called: $url'); // Add this
  
  final response = await client.get(url);
  print('Response status code: ${response.statusCode}'); // Add this
  print('Response body: ${response.body}');
   // Add this
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final errorData = json.decode(response.body);
    print('Error data received: $errorData'); // Add this
    final errorMessage = errorData['message'] ?? 'Failed to load user';
    throw Exception('HTTP ${response.statusCode}: $errorMessage');
  }
}

  @override
  Future<void> updateUser(String userId, User user) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nom': user.nom,
        'prenom': user.prenom,
        'email': user.email,
        'date': user.date,
        'phone': user.phone,
        'region': user.region,
        'genre': user.genre,
        'password': user.password,
      }),
    );
    if (response.statusCode != 200) {
      final errorResponse = json.decode(response.body);
      throw Exception('Failed to update user: ${errorResponse['message']}');
    }
  }

  @override
  Future<void> sendCodeToEmail(String email) async {
    // Use your server's IP address here instead of localhost.
    final url = Uri.parse('http://192.168.1.18:3000/api/forgot-password');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send code');
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
      if (response.statusCode != 200) {
        throw Exception('Invalid or expired code');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/reset-password');
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
          'code': '', // Modify if your endpoint requires a verification code
        }),
      );
      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

@override
Future<String> uploadImage(String filePath, String userId) async {
  final url = Uri.parse('$baseUrl/upload');
  var request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('image', filePath));
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    final imageUrl = responseData['imageUrl'];

    // Update the user's imageUrl in the database
    await updateUserImage(userId, imageUrl);

    return imageUrl; // Ensure a String is returned
  } else {
    throw Exception('Image upload failed: ${response.body}');
  }
}

  @override
  Future<void> updateUserImage(String userId, String imageUrl) async {
    final url = Uri.parse('$baseUrl/users/$userId/image');
    try {
      final response = await client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': imageUrl}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update user image');
      }
    } catch (e) {
      throw Exception('Error updating user image: $e');
    }
  }
}
