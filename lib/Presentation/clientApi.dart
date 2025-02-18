import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<http.Response> put(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('Making PUT request to: $uri');
      debugPrint('Request body: ${jsonEncode(body)}');

      final response = await _httpClient.put(
        uri,
        body: jsonEncode(body), // Encode the body as JSON string
        headers: {
          'Content-Type': 'application/json',
          ...?headers ?? {},
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response;
    } catch (e) {
      debugPrint('API client error: $e');
      rethrow;
    }
  }
}
