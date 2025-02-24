import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:dio/dio.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItem>> getWishlistItems(String userId);
  Future<void> addToWishlist(WishlistItem item);
  Future<void> removeFromWishlist(String itemId);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final Dio dio;
  final String baseUrl = 'http://localhost:3000/api/wishlist'; // Base URL for wishlist API

  WishlistRemoteDataSourceImpl(this.dio);

@override
Future<List<WishlistItem>> getWishlistItems(String userEmail) async {
  try {
    print('Fetching wishlist for user: $userEmail');
    
    final response = await dio.get(
      '$baseUrl/user/$userEmail',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );

    print('Response status: ${response.statusCode}');
    print('Response data: ${response.data}'); // Ajoutez ce log pour voir les données reçues

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to get wishlist items: ${response.statusMessage}',
      );
    }

    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((item) {
      try {
        return WishlistItem.fromJson(item as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing item: $item');
        print('Error details: $e');
        rethrow;
      }
    }).toList();
  } catch (e) {
    print('Error in getWishlistItems: $e');
    rethrow;
  }
}
 @override
Future<void> addToWishlist(WishlistItem item) async {
  try {
    final response = await dio.post(
      baseUrl,
      data: {
        'userEmail': item.userId, // Envoyez userEmail au lieu de userId
        'productId': item.productId,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to add item to wishlist: ${response.statusMessage}',
      );
    }
  } catch (e) {
    print('Error in addToWishlist: $e');
    rethrow;
  }
}

  @override
  Future<void> removeFromWishlist(String itemId) async {
    try {
      await dio.delete('$baseUrl/$itemId');
    } catch (e) {
      throw Exception('Failed to remove item from wishlist: $e');
    }
  }
}