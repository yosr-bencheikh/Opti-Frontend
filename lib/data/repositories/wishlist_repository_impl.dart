import 'package:opti_app/data/data_sources/wishlist_remote_datasource.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;

  WishlistRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<WishlistItem>> getWishlistItems(String userId) {
    return remoteDataSource.getWishlistItems(userId);
  }

  @override
  Future<void> addToWishlist(WishlistItem item) {
    return remoteDataSource.addToWishlist(item);
  }

  @override
  Future<void> removeFromWishlist(String itemId) {
    return remoteDataSource.removeFromWishlist(itemId);
  }
}