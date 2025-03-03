import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/data/data_sources/wishlist_remote_datasource.dart';

class WishlistController extends GetxController {
  final WishlistRemoteDataSource wishlistRemoteDataSource;
  final RxList<WishlistItem> wishlistItems = <WishlistItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<String> _wishlistProductIds = <String>[].obs;

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
      final items =
          await wishlistRemoteDataSource.getWishlistItems(currentUserEmail!);
      wishlistItems.value = items;

      // Mettre à jour la liste des IDs de produits
      _wishlistProductIds.value = items.map((item) => item.productId).toList();
    } catch (e) {
      print('Error loading wishlist: $e');
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
  Future<void> refreshWishlist() async {
    try {
      if (currentUserEmail != null && currentUserEmail!.isNotEmpty) {
        // Fetch fresh wishlist data from server
        final items = await wishlistRemoteDataSource.getWishlistItems(currentUserEmail!);
        
        // Update the wishlist items
        wishlistItems.clear();
        wishlistItems.addAll(items);
      }
    } catch (e) {
      print('Error refreshing wishlist: ${e.toString()}');
    }
  }
  Future<void> removeFromWishlist(String productId) async {
    try {
      // Check authentication status before proceeding
      isLoading.value = true;
      await wishlistRemoteDataSource.removeFromWishlist(productId);
      // Remove item locally to give immediate feedback
      wishlistItems.removeWhere((item) => item.productId == productId);
      updateWishlistState();

      Get.snackbar(
        'Success',
        'Item removed from wishlist',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      print('Error removing from wishlist: $e');

      // Check for authentication errors specifically
      if (e.toString().contains('401') ||
          e.toString().contains('token') ||
          e.toString().contains('auth')) {
        Get.snackbar(
          'Authentication Error',
          'Your session has expired. Please log in again.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        // Optionally redirect to login
        // authController.logout();
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove item from wishlist',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    } finally {
      isLoading.value = false;
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

  void updateWishlistState() {
    update(); // Notifier tous les widgets dépendants que l'état a changé
  }

  Future<void> addToWishlist(WishlistItem item) async {
    try {
      await wishlistRemoteDataSource.addToWishlist(item);
      await loadWishlistItems(); // Reload to get updated list
      updateWishlistState();
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

// Add this to your WishlistController class
  void synchronizeWishlist() async {
    if (currentUserEmail != null && currentUserEmail!.isNotEmpty) {
      // Only reload if we're not already loading
      if (!isLoading.value) {
        await loadWishlistItems();
      }
    }
  }

  Future<bool> checkProductInWishlistRealtime(String productId) async {
    if (currentUserEmail == null || currentUserEmail!.isEmpty) {
      return false;
    }

    try {
      // Try to get the latest data from server first
      final items =
          await wishlistRemoteDataSource.getWishlistItems(currentUserEmail!);
      // Update our local copy
      wishlistItems.value = items;
      // Return if product is in wishlist
      return items.any((item) => item.productId == productId);
    } catch (e) {
      print('Error checking product in wishlist: $e');
      // Fall back to local cache if server check fails
      return wishlistItems.any((item) => item.productId == productId);
    }
  }
}
