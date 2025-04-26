import 'dart:convert';
import 'package:http/http.dart' as http;

class StoreReviewDataSource {
  final String baseUrl = 'http://192.168.1.8:3000/api';

  Future<List<dynamic>> fetchBoutiqueReviews(String boutiqueId) async {
    final url = Uri.parse('$baseUrl/boutique-reviews/$boutiqueId');
    final response = await http.get(url);

    print('[fetchBoutiqueReviews] URL: $url, status: ${response.statusCode}');
    print('[fetchBoutiqueReviews] Response: ${response.body}');

    if (response.statusCode == 200) {
      // Parse the response as a List<dynamic>
      final List<dynamic> reviews = json.decode(response.body);
      return reviews;
    } else {
      // Log the error response
      print(
          '[fetchBoutiqueReviews] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load boutique reviews');
    }
  }

  // Add this new method to fetch boutique stats
  Future<Map<String, dynamic>> fetchBoutiqueStats(String boutiqueId) async {
    final url = Uri.parse('$baseUrl/boutique-stats/$boutiqueId');
    final response = await http.get(url);

    print('[fetchBoutiqueStats] URL: $url, status: ${response.statusCode}');
    print('[fetchBoutiqueStats] Response: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('[fetchBoutiqueStats] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load boutique stats');
    }
  }

    Future<Map<String, dynamic>> submitBoutiqueReview(String boutiqueId,
      String customerId, String reviewText, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/boutique-reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'boutiqueId': boutiqueId,
          'customerId': customerId,
          'reviewText': reviewText,
          'rating': rating,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['review'],
          'boutiqueStats': responseData['boutiqueStats']
        };
      } else if (response.statusCode == 400 &&
          responseData['error']?.contains('inappropriate language') == true) {
        return {
          'success': false,
          'error': responseData['error'],
          'toxicityScores': responseData['toxicityScores']
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to submit boutique review'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

   Future<Map<String, dynamic>> deleteBoutiqueReview(
      String reviewId, String customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/boutique-reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customerId': customerId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'boutiqueStats': responseData['boutiqueStats']
        };
      } else {
        String errorMessage =
            responseData['error'] ?? 'Failed to delete boutique review';
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error: ${e.toString()}');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<dynamic> getStoreWishlist(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.body}');
    }
  }

  Future<dynamic> postStoreWishlist(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/storewishlist'), // Change this line
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.body}');
    }
  }

  // DELETE request
  Future<dynamic> deleteStoreWishlist(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete data: ${response.body}');
    }
  }
}
