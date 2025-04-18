import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/data/data_sources/storeReview_data_source.dart';

class StoreWishlistController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreReviewDataSource _dataSource = StoreReviewDataSource();

  final RxMap<String, bool> favoriteStores = <String, bool>{}.obs;

  Future<void> loadFavorites() async {
    if (_authController.currentUser == null) return;

    try {
      final customerId = _authController.currentUser!.id;
      final endpoint = '/wishlist/$customerId';
      final response = await _dataSource.getStoreWishlist(endpoint);

      favoriteStores.clear();

      if (response is List) {
        for (var item in response) {
          final boutiqueId = item['boutiqueId']['_id'];
          favoriteStores[boutiqueId] = true;
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<bool> checkFavoriteStatus(String boutiqueId) async {
    if (_authController.currentUser == null) return false;

    try {
      final customerId = _authController.currentUser!.id;
      final endpoint = '/wishlist/check/$customerId/$boutiqueId';
      final response = await _dataSource.getStoreWishlist(endpoint);

      final bool isFavorite = response['isFavorite'] ?? false;
      favoriteStores[boutiqueId] = isFavorite;
      return isFavorite;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Check if store is favorite based on database state
  bool isFavorite(String storeId) {
    return favoriteStores[storeId] ?? false;
  }

  // Initialize favorite status for an individual optician card
  Future<void> initOpticianFavoriteStatus(String boutiqueId) async {
    if (!favoriteStores.containsKey(boutiqueId)) {
      await checkFavoriteStatus(boutiqueId);
    }
  }

  Future<bool> toggleFavorite(String boutiqueId) async {
    if (_authController.currentUser == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez vous connecter pour ajouter des favoris',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final customerId = _authController.currentUser!.id;
      final endpoint = '/wishlist';
      final data = {
        'customerId': customerId,
        'boutiqueId': boutiqueId,
      };

      final response = await _dataSource.postStoreWishlist(endpoint, data);

      if (response['error'] != null) {
        throw Exception(response['error']);
      }

      final bool isFavorite = response['isFavorite'] ?? false;
      favoriteStores[boutiqueId] = isFavorite;

      Get.snackbar(
        'Succès',
        isFavorite
            ? 'Boutique ajoutée aux favoris'
            : 'Boutique retirée des favoris',
        snackPosition: SnackPosition.BOTTOM,
      );

      return isFavorite;
    } catch (e) {
      print('Error toggling favorite: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour les favoris: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return favoriteStores[boutiqueId] ?? false;
    }
  }

  Future<bool> removeFavorite(String boutiqueId) async {
    if (_authController.currentUser == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez vous connecter pour gérer vos favoris',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      final customerId = _authController.currentUser!.id;
      final endpoint = '/wishlist/$customerId/$boutiqueId';
      await _dataSource.deleteStoreWishlist(endpoint);

      favoriteStores[boutiqueId] = false;

      Get.snackbar(
        'Succès',
        'Boutique retirée des favoris',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de retirer des favoris',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadFavorites();

    // Assuming AuthController uses GetBuilder or similar to update
    ever(_authController.isLoggedIn, (_) {
      loadFavorites();
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure favorites are loaded when controller is ready
    loadFavorites();
  }
}
