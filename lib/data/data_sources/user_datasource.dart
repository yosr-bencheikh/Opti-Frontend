import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/user.dart';
import 'package:http_parser/http_parser.dart';
class UserDataSource {
  final String baseUrl = 'http://192.168.1.22:3000/api';


  /// Ajouter un nouvel utilisateur
  Future<void> addUser(User user) async {
    try {
      print('Adding new user: ${user.email}');
      final response = await http.post(
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

  Future<User> getUserByEmail(String email) async {
    try {
      print('Fetching user by email: $email');
      final response = await http.get(
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
  
  Future<List<User>> getUsers() async {
    try {
      print('Fetching users from: $baseUrl/users');
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      final response = await http.put(
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
  
  Future<void> deleteUser(String email) async {
    try {
      final response = await http.delete(
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
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      filePath,
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
      throw Exception('Image upload failed: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error in uploadImage method: $e');
    throw Exception('Image upload failed: $e');
  }
}

/// Update the user's image URL in the database
Future<void> updateUserImage(String email, String imageUrl) async {
  final user = await getUserByEmail(email);
  user.imageUrl = imageUrl;
  await updateUser(user);
}


}