import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
  Future<void> updateUserImage(String userId, String imageUrl);
  Future<Map<String, dynamic>> getUserByEmail(String email);
  Future<String> refreshToken(String refreshToken);
  Future<bool> verifyToken(String token);
  Future<void> deleteUserImage(String email);
  Future<Map<String, dynamic>> getUserById(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;


  final String baseUrl = 'http://192.168.1.8:3000/api';

  static String? verifiedEmail; // Made statica
  static String? verificationCode;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/id/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        return userData;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user by ID: ${e.toString()}');
    }
  }

  void sendPlayerIdToBackend(String userId) async {
    try {
      final pushSubscription = await OneSignal.User.pushSubscription;
      final String? playerId = pushSubscription.id;

      if (playerId != null) {
        debugPrint('Sending Player ID to backend: $playerId');

        // Send the Player ID to your backend
        final response = await http.post(
          Uri.parse('$baseUrl/store-player-id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'playerId': playerId,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('Player ID stored successfully');
        } else {
          debugPrint('Failed to store Player ID: ${response.body}');
        }
      } else {
        debugPrint('Player ID is null');
      }
    } catch (e) {
      debugPrint('Error sending Player ID: $e');
    }
  }

  @override
  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse('$baseUrl/refresh-token');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['token']; // Return the new access token
      } else {
        throw Exception('Failed to refresh token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$email'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        return userData;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user by email: ${e.toString()}');
    }
  }

  @override
  Future<String> loginWithEmail(String email, String password) async {
    try {
      debugPrint('Inside loginWithEmail: Sending request...');

      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      debugPrint(
          'Received response: ${response.statusCode}, Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        debugPrint('Login successful, token: ${responseData['token']}');

        // Extract userId from the response
        final userId =
            responseData['userId']; // Ensure your backend returns userId
        if (userId != null) {
          // Send the Player ID to the backend
          sendPlayerIdToBackend(userId); // Await the function call
        }

        return responseData['token'];
      } else {
        debugPrint(
            'Login failed: ${responseData['message'] ?? 'Unknown error'}');
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      debugPrint('Error inside loginWithEmail: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('An error occurred: ${e.toString()}');
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
          // Extract userId from the response
          final userId = data['userId']; // Ensure your backend returns userId
          if (userId != null) {
            // Send the Player ID to the backend
            sendPlayerIdToBackend(userId); // Await the function call
          }

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
  Future<void> updateUser(String email, User user) async {
    try {
      final url = Uri.parse('$baseUrl/update/$email');

      final Map<String, dynamic> userData = {
        'nom': user.nom,
        'prenom': user.prenom,
        'email': user.email,
        'date': user.date,
        'phone': user.phone,
        'region': user.region,
        'genre': user.genre,
      };

      // Only include password if it's being updated
      if (user.password != null && user.password!.isNotEmpty) {
        userData['password'] = user.password;
      }

      final response = await client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        print('Update successful: ${response.body}');
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('Failed to update user: ${errorResponse['message']}');
      }
    } catch (e) {
      print('Data source update error: $e');
      throw Exception('Error updating user: $e');
    }
  }

  @override
  Future<void> sendCodeToEmail(String email) async {
    
    final url = Uri.parse('$baseUrl/forgot-password');
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
  Future<String> uploadImage(String filePath, String email) async {
    final url = Uri.parse(
        '$baseUrl/upload/$email/image'); // Adjusted URL to match the backend endpoint
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final imageUrl = responseData['imageUrl'];

      // Update the user's image URL in the database by email
      await updateUserImage(email, imageUrl);

      return imageUrl; // Return the uploaded image URL
    } else {
      throw Exception('Image upload failed: ${response.body}');
    }
  }

  @override
  Future<void> updateUserImage(String email, String imageUrl) async {
    final url = Uri.parse('$baseUrl/upload/$email/image'); // URL correcte
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode == 200) {
        print("Image URL updated successfully for user $email");
      } else {
        throw Exception('Failed to update user image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating user image: $e');
    }
  }

  @override
  Future<void> deleteUserImage(String email) async {
    final url = Uri.parse('$baseUrl/upload/$email/image'); // URL correcte
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Image deleted successfully for user $email");
      } else {
        throw Exception('Failed to delete user image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting user image: $e');
    }
  }
}
