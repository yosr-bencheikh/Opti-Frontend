import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/data/data_sources/wishlist_remote_datasource.dart';

class WishlistController extends GetxController {
  final WishlistRemoteDataSource wishlistRemoteDataSource;
  final RxList<WishlistItem> wishlistItems = <WishlistItem>[].obs;
  final RxBool isLoading = false.obs;

  String? currentUserEmail;

  WishlistController(this.wishlistRemoteDataSource);

  void initUser(String userEmail) {
    currentUserEmail = userEmail;
    loadWishlistItems();
  }

  Future<void> loadWishlistItems() async {
    if (currentUserEmail == null || currentUserEmail!.isEmpty) {
      Get.snackbar('Error', 'User not initialized');
      return;
    }

    isLoading.value = true;
    try {
      print('Loading wishlist for user: $currentUserEmail'); // Debug log
      final items = await wishlistRemoteDataSource.getWishlistItems(currentUserEmail!);
      wishlistItems.value = items;
      print('Loaded ${items.length} wishlist items'); // Debug log
    } catch (e) {
      print('Error loading wishlist: $e'); // Debug log
      Get.snackbar(
        'Error',
        'Unable to load wishlist items. Please try again later.',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      await wishlistRemoteDataSource.removeFromWishlist(productId);
      await loadWishlistItems(); // Reload after successful removal
      Get.snackbar(
        'Success',
        'Item removed from wishlist',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove item from wishlist',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      print('Error removing from wishlist: $e'); // For debugging
    }
  }

   bool isProductInWishlist(String productId) {
    return wishlistItems.any((item) => item.productId == productId);
  }

  WishlistItem? getWishlistItemByProductId(String productId) {
    try {
      return wishlistItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addToWishlist(WishlistItem item) async {
    try {
      await wishlistRemoteDataSource.addToWishlist(item);
      await loadWishlistItems(); // Reload to get updated list
      Get.snackbar(
        'Success',
        'Item added to wishlist',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      print('Error adding to wishlist: $e');
      throw Exception('Failed to add item to wishlist');
    }
  }

}