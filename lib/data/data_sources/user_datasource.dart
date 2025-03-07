import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/user.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

abstract class UserDataSource {
  Future<void> addUser(User user);
  Future<User> getUserByEmail(String email);
  Future<List<User>> getUsers();
  Future<void> updateUser(User user);
  Future<void> deleteUser(String email);
  Future<String> uploadImage(String filePath, String email);
  Future<void> updateUserImage(String email, String imageUrl);
  Future<User> getUserById(String userId);
}

class UserDataSourceImpl implements UserDataSource {
  final http.Client client;
  final String baseUrl = 'http://localhost:3000/api';
  final dio_pkg.Dio _dio;
UserDataSourceImpl({required this.client}) : _dio = dio_pkg.Dio();
  @override
  Future<void> addUser(User user) async {
    try {
      print('Adding new user: ${user.email}');
      final response = await client.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to add user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding user: $e');
      throw Exception('Error adding user: $e');
    }
  }

  @override
  Future<User> getUserByEmail(String email) async {
    try {
      print('Fetching user by email: $email');
      final response = await client.get(
        Uri.parse('$baseUrl/users/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return User.fromJson(jsonMap);
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user: $e');
      throw Exception('Error fetching user: $e');
    }
  }

@override
Future<List<User>> getUsers() async {
  try {
    print('Début de la requête getUsers()');
    
    final response = await client.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 8));
    
    print('Réponse reçue: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('Décodage du corps de la réponse');
      final users = await compute(_parseUsers, response.body);
      print('${users.length} utilisateurs chargés');
      return users;
    } else {
      print('Erreur HTTP: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception dans getUsers(): $e');
    if (e is TimeoutException) {
      throw Exception('Le serveur met trop de temps à répondre');
    }
    throw Exception('Error fetching users: $e');
  }
}

// Fonction isolée pour le décodage JSON (à définir en dehors de la classe)
List<User> _parseUsers(String responseBody) {
  final List<dynamic> jsonList = json.decode(responseBody);
  return jsonList.map((json) => User.fromJson(json)).toList();
}
Future<User> getUserById(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return User.fromJson(data);
  } else {
    throw Exception('Failed to load user');
  }
}

  @override
  Future<void> updateUser(User user) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/users/${user.email}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  @override
  Future<void> deleteUser(String email) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/users/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
  // Ajouter cette méthode à votre classe de contrôleur
Future<String> uploadImageWeb(Uint8List imageBytes, String fileName, String email) async {
  try {
    final formData = dio_pkg.FormData.fromMap({
      'image': dio_pkg.MultipartFile.fromBytes(
        imageBytes,
        filename: fileName,
      ),
      'email': email, // Ensure this matches the backend expectation
    });

    final response = await _dio.post(
      '$baseUrl/upload',
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data['url'] ?? '';
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  } catch (e) {
    print('Error during web image upload: $e');
    throw e;
  }
}

  @override
  Future<String> uploadImage(String filePath, String email) async {
    try {
      print('Starting image upload for email: $email, file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final url = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', url);

      // Add the image file to the request
      request.files.add(await http.MultipartFile.fromPath('image', filePath,
          contentType: MediaType('image', 'jpeg') // Explicitly set content type
          ));

      // Add email as a field
      request.fields['email'] = email;

      print('Sending upload request to: $url');
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'];

        print('Image uploaded successfully. URL: $imageUrl');

        // Update the user's image URL in the database
        try {
          await updateUserImage(email, imageUrl);
          print('User image URL updated successfully');
        } catch (e) {
          print('Error updating user image URL: $e');
          // Continue even if this fails, at least we have the image URL
        }

        return imageUrl; // Return the uploaded image URL
      } else {
        throw Exception(
            'Image upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in uploadImage method: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  @override
  Future<void> updateUserImage(String email, String imageUrl) async {
    final user = await getUserByEmail(email);
    user.imageUrl = imageUrl;
    await updateUser(user);
  }
}
