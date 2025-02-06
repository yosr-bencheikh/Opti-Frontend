import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRemoteDataSource {
  final String baseUrl = 'http://127.0.0.1:3000/api';

  Future<String> loginWithEmail(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
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
    throw Exception(responseData['message'] ?? 'Login Failed');
  }

  Future<String> loginWithGoogle(String token) async {
    final url = Uri.parse('$baseUrl/google-login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData['token'] != null) {
      return responseData['token'];
    }
    throw Exception(responseData['message'] ?? 'Google Login Failed');
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
}
