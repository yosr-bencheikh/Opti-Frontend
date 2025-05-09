import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewDataSource {
  final String baseUrl = 'http://localhost:3000/api';
  
  Future<List<dynamic>> fetchReviews(String productId) async {
    final response = await http.get(Uri.parse('$baseUrl/reviews/$productId'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }
  
  Future<Map<String, dynamic>> submitReview(
      String productId, String userId, String reviewText, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
          'reviewText': reviewText,
          'rating': rating,
        }),
      );
      
      final responseData =
          response.statusCode == 201 || response.statusCode == 400
              ? jsonDecode(response.body)
              : {'error': 'Server error: ${response.statusCode}'};
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
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
          'error': responseData['error'] ?? 'Failed to submit review'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
  
  Future<Map<String, dynamic>> deleteReview(
      String reviewId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      
      // Log the response status and body for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      // Check if the response was successful
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Review deleted successfully'};
      } else {
        // If there is an error, return the error message from the response
        String errorMessage =
            responseData['error'] ?? 'Failed to delete review';
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      // Handle network or other exceptions
      print('Error: ${e.toString()}');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
  
  // Add this new method to update product ratings directly
  Future<Map<String, dynamic>> updateProductRatings(
      String productId, double averageRating, int totalReviews) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'averageRating': averageRating,
          'totalReviews': totalReviews,
        }),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'Failed to update product ratings: ${response.body}'
        };
      }
    } catch (e) {
      print('Error updating product ratings: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}