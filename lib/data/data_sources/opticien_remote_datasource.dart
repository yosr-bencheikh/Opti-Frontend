import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/Opticien.dart';

abstract class OpticienRemoteDataSource {
  Future<List<Opticien>> getOpticiens();
}

class OpticienRemoteDataSourceImpl implements OpticienRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  OpticienRemoteDataSourceImpl({
    required this.client,
    // Make sure this matches your actual server URL and port
    this.baseUrl = 'http://localhost:3000',
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
}
