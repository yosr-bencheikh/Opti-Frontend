import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItem>> getWishlistItems(String userId);
  Future<void> addToWishlist(WishlistItem item);
  Future<void> removeFromWishlist(String itemId);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final Dio dio;
  final String baseUrl =
      'http://192.168.1.22:3000/api'; // Update with your actual API base URL

  WishlistRemoteDataSourceImpl(this.dio);

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<List<WishlistItem>> getWishlistItems(String userEmail) async {
    try {
      final response = await dio.get('$baseUrl/wishlist/user/$userEmail');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => WishlistItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wishlist items');
      }
    } catch (e) {
      print('Error fetching wishlist items: $e');
      throw Exception('Failed to load wishlist items: $e');
    }
  }

  @override
  Future<void> addToWishlist(WishlistItem item) async {
    try {
      await dio.post('$baseUrl/wishlist', data: {
        'productId': item.productId,
        'userEmail': item.userId,
      });
    } catch (e) {
      print('Error adding to wishlist: $e');
      throw Exception('Failed to add item to wishlist: $e');
    }
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    try {
      // Get the token
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Make the request with the token in the Authorization header
      final response = await dio.delete(
        '$baseUrl/wishlist/$productId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to remove item from wishlist: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      throw Exception('Failed to remove item from wishlist: $e');
    }
  }

  @override
  Future<bool> isProductInWishlist(String userEmail, String productId) async {
    try {
      final response =
          await dio.get('$baseUrl/wishlist/check/$userEmail/$productId');

      if (response.statusCode == 200) {
        return response.data['isInWishlist'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }
}
