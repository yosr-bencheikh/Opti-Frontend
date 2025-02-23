import 'package:opti_app/domain/entities/wishlist_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> getWishlistItems(String userId);
  Future<void> addToWishlist(WishlistItem item);
  Future<void> removeFromWishlist(String itemId);
}
