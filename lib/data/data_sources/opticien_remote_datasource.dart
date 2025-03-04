import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/Opticien.dart';

abstract class OpticienRemoteDataSource {
  Future<List<Opticien>> getOpticiens();
  Future<void> addOpticien(Opticien opticien);
  Future<void> updateOpticien(String id, Opticien opticien);
  Future<void> deleteOpticien(String id);
}

class OpticienRemoteDataSourceImpl implements OpticienRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  OpticienRemoteDataSourceImpl({
    required this.client,
    // Make sure this matches your actual server URL and port
    this.baseUrl = 'http://192.168.1.22:3000',
  });

  @override
  Future<List<Opticien>> getOpticiens() async {
    try {
      // Add logging to verify the URL
      final url = '$baseUrl/opticiens';
      print('Attempting to fetch opticians from: $url');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Opticien.fromJson(json)).toList();
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching opticians: $e');
      throw Exception('Failed to fetch opticians: $e');
    }
  }
  
  @override
  Future<void> addOpticien(Opticien opticien) async {
    try {
      final url = '$baseUrl/opticiens';
      print('Attempting to add optician at: $url');
      
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(opticien.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 201) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error adding optician: $e');
      throw Exception('Failed to add optician: $e');
    }
  }
  
  @override
  Future<void> updateOpticien(String id, Opticien opticien) async {
    try {
      final url = '$baseUrl/opticiens/$id';
      print('Attempting to update optician at: $url');
      
      final response = await client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(opticien.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error updating optician: $e');
      throw Exception('Failed to update optician: $e');
    }
  }
  
  @override
  Future<void> deleteOpticien(String id) async {
    try {
      final url = '$baseUrl/opticiens/$id';
      print('Attempting to delete optician at: $url');
      
      final response = await client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error deleting optician: $e');
      throw Exception('Failed to delete optician: $e');
    }
  }
}