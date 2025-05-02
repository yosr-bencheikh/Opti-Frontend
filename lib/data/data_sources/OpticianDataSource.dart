import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:dio/dio.dart' as dio_pkg; // For web image upload
import 'package:opti_app/domain/entities/Optician.dart';

abstract class OpticianDataSource {
  Future<List<Optician>> getOpticians();
  Future<Optician> addOptician(Optician optician);
  Future<Optician> updateOptician(Optician optician);
  Future<bool> deleteOptician(String id);
  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String email);
  Future<String> uploadImage(String filePath, String email);
  Future<void> updateOpticianImage(String email, String imageUrl);
  Future<Optician> getOpticianByEmail(String email);
  Future<String> loginWithEmail(String email, String password);

  Future<void> sendPasswordResetEmail(String email);
  Future<bool> verifyResetCode(String email, String code);
  Future<bool> resetPassword(String email, String code, String newPassword);
}

class OpticianDataSourceImpl implements OpticianDataSource {
  final String baseUrl =

      'http://localhost:3000/api'; // Replace with your API base URL


  final dio_pkg.Dio _dio = dio_pkg.Dio(); // For web image upload

@override
Future<void> sendPasswordResetEmail(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/send-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send reset email: ${response.body}');
    }
  } catch (e) {
    throw Exception('Failed to send reset email: $e');
  }
}

@override
Future<bool> verifyResetCode(String email, String code) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Invalid verification code');
    }
  } catch (e) {
    throw Exception('Verification failed: $e');
  }
}

@override
Future<bool> resetPassword(String email, String code, String newPassword) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Password reset failed: ${response.body}');
    }
  } catch (e) {
    throw Exception('Password reset failed: $e');
  }
}
  @override
  Future<String> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loginOpticien'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      } else {
        throw Exception(
            'Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<List<Optician>> getOpticians() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/opticians'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Optician.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load opticians: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch opticians: $e');
    }
  }

  @override
  Future<Optician> addOptician(Optician optician) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/opticians'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(optician.toJson()),
      );
      if (response.statusCode == 201) {
        return Optician.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add optician: $e');
    }
  }

  @override
  Future<Optician> updateOptician(Optician optician) async {
    if (optician.id == null) {
      throw Exception('Cannot update optician without ID');
    }
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/opticians/${optician.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(optician.toJson()),
      );
      if (response.statusCode == 200) {
        return Optician.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update optician: $e');
    }
  }

  @override
  Future<bool> deleteOptician(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/opticians/$id'),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete optician: $e');
    }
  }

  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String email) async {
    try {
      final formData = dio_pkg.FormData.fromMap({
        'image': dio_pkg.MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
        'email': email,
      });

      // Correction: utiliser la bonne route API
      final response = await _dio.post(
        '$baseUrl/upload-optician-image',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['imageUrl'] ??
            ''; // Assurez-vous que la clé correspond à celle renvoyée par votre API
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during web image upload: $e');
      throw e;
    }
  }

  Future<String> uploadImage(String filePath, String email) async {
    try {
      print('Starting image upload for email: $email, file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Correction: utiliser la bonne route API
      final url = Uri.parse('$baseUrl/upload-optician-image');
      var request = http.MultipartRequest('POST', url);

      // Add the image file to the request
      request.files.add(await http.MultipartFile.fromPath(
          'image', // Assurez-vous que cela correspond au nom attendu par multer
          filePath,
          contentType: MediaType('image', 'jpeg')));

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
  Future<void> updateOpticianImage(String email, String imageUrl) async {
    try {
      final optician = await getOpticianByEmail(email);
      optician.imageUrl = imageUrl;
      await updateOptician(optician);
    } catch (e) {
      throw Exception('Failed to update optician image: $e');
    }
  }

  // Helper method to fetch optician by email
  @override
Future<Optician> getOpticianByEmail(String email) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/opticians/findByEmail?email=$email'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Optician.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Optician with email $email not found');
    } else {
      throw Exception('Failed to get optician: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to get optician by email: $e');
  }
}
}
