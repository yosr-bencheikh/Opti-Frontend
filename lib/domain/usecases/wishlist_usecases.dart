import 'package:dio/dio.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

abstract class WishlistUseCases {
  Future<List<WishlistItem>> getWishlistItems(String userId);
  Future<WishlistItem> addToWishlist(String productId, String userId);
  Future<bool> removeFromWishlist(String wishlistItemId);
}

class WishlistUseCasesImpl implements WishlistUseCases {
  final Dio dio;
  final String baseUrl;

  WishlistUseCasesImpl({
    required this.dio,
    this.baseUrl = 'http://localhost:3000/api',
  });

  Future<Product> _fetchProductDetails(String productId) async {
    try {
      final response = await dio.get('$baseUrl/products/$productId');
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch product details. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow;
    }
  }

  @override
  Future<List<WishlistItem>> getWishlistItems(String userId) async {
    try {
      final response = await dio.get('$baseUrl/wishlist/user/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data as List<dynamic>;
        return items.map((item) => WishlistItem.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to get wishlist items. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting wishlist items: $e');
      throw Exception('Failed to get wishlist items: $e');
    }
  }

  @override
  Future<WishlistItem> addToWishlist(String productId, String userId) async {
    try {
      // First fetch the product details
      final product = await _fetchProductDetails(productId);
      
      // Create wishlist item request
      final response = await dio.post('$baseUrl/wishlist', data: {
        'productId': productId,
        'userId': userId,
      });

      if (response.statusCode == 201) {
        // Create WishlistItem with the response data
        return WishlistItem(
          id: response.data['_id'],
          product: product,
          userId: userId,
          productId: productId,
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to add item to wishlist. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
      throw Exception('Failed to add item to wishlist: $e');
    }
  }

  @override
  Future<bool> removeFromWishlist(String wishlistItemId) async {
    try {
      final response = await dio.delete('$baseUrl/wishlist/$wishlistItemId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing from wishlist: $e');
      throw Exception('Failed to remove item from wishlist: $e');
    }
  }
}