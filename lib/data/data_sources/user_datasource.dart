import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/user.dart';

class UserDataSource {
  final String baseUrl = 'http://localhost:3000/api';

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
}
