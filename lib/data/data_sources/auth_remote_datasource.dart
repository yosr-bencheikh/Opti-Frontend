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
}