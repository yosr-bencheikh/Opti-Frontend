import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<String> loginWithEmail(String email, String password);
  Future<String> loginWithGoogle(String token);
  Future<void> signUp(User user);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://127.0.0.1:3000/api';

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
          'nom': user.nom,
          'prenom': user.prenom,
          'email': user.email,
          'date': user.date,
          'password': user.password,
          'phone': user.phone,
          'region': user.region,
          'gender': user.gender,
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
}