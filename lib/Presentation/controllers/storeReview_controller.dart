import 'package:get/get.dart';
import 'package:opti_app/data/repositories/storeReview_repository_impl.dart';
import 'package:opti_app/domain/entities/StoreReview.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class StoreReviewController extends GetxController {
  final StoreReviewRepository _repository;
  final UserRepository _userRepo;
  final RxList<StoreReview> reviews = <StoreReview>[].obs;
  final RxBool isLoading = false.obs;
  final Rxn<String> error = Rxn<String>();
  final RxMap<String, String> _customerNamesCache = <String, String>{}.obs;

  StoreReviewController(this._repository, this._userRepo);

  Future<void> loadReviews(String boutiqueId) async {
    try {
      isLoading(true);
      error(null);

      // 1. Fetch reviews with populated user data
      final result = await _repository.getBoutiqueReviews(boutiqueId);

      // 2. Parse reviews with included user information
      final reviewsList =
          result.map((json) => StoreReview.fromJson(json)).toList();

      // 3. Directly assign to observable list
      reviews.assignAll(reviewsList);
    } catch (e, stackTrace) {
      print('Error loading reviews: $e');
      print(stackTrace);
      error(e.toString());
      reviews.clear();
    } finally {
      isLoading(false);
    }
  }

  Future<void> _fetchUserName(String userId) async {
    if (_customerNamesCache.containsKey(userId)) return;

    try {
      final user = await _userRepo.getUserById(userId);
      _customerNamesCache[userId] = '${user.prenom} ${user.nom}';
    } catch (e) {
      print('Erreur récupération utilisateur $userId: $e');
      _customerNamesCache[userId] = 'Client inconnu';
    }
  }

  String getCustomerName(String userId) {
    return _customerNamesCache[userId] ?? 'Chargement...';
  }

  Future<bool> addReview({
    required String boutiqueId,
    required String customerId,
    required String reviewText,
    required int rating,
    String? customerName,
    String? customerImageUrl,
  }) async {
    try {
      print(
          'Début de l\'ajout d\'un avis pour la boutique: $boutiqueId, CustomerID: $customerId');
      isLoading(true);
      final response = await _repository.addBoutiqueReview(
        boutiqueId,
        customerId,
        reviewText,
        rating,
      );
      print('Réponse de l\'ajout: $response');

      if (response['success'] == true) {
        print('Avis ajouté avec succès, rechargement des avis.');
        await loadReviews(boutiqueId); // Refresh the list
        return true;
      } else {
        final errMsg = response['error'] ?? 'Failed to add review';
        print('Erreur lors de l\'ajout de l\'avis: $errMsg');
        error(errMsg);
        return false;
      }
    } catch (e, stackTrace) {
      print('Exception lors de l\'ajout de l\'avis: $e');
      print(stackTrace);
      error(e.toString());
      return false;
    } finally {
      isLoading(false);
      print('Fin de l\'ajout d\'un avis');
    }
  }

  Future<bool> deleteReview(String reviewId, String customerId) async {
    try {
      print(
          'Début de la suppression de l\'avis: $reviewId pour CustomerID: $customerId');
      isLoading(true);
      final response =
          await _repository.removeBoutiqueReview(reviewId, customerId);
      print('Réponse de la suppression: $response');

      if (response['success'] == true) {
        reviews.removeWhere((review) => review.id == reviewId);
        print(
            'Avis supprimé avec succès, nombre d\'avis restants: ${reviews.length}');
        return true;
      } else {
        final errMsg = response['error'] ?? 'Failed to delete review';
        print('Erreur lors de la suppression de l\'avis: $errMsg');
        error(errMsg);
        return false;
      }
    } catch (e, stackTrace) {
      print('Exception lors de la suppression de l\'avis: $e');
      print(stackTrace);
      error(e.toString());
      return false;
    } finally {
      isLoading(false);
      print('Fin de la suppression de l\'avis');
    }
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    final avg = total / reviews.length;
    print(
        'Calcul de la note moyenne: $avg (Total: $total, Nombre: ${reviews.length})');
    return avg;
  }

  List<StoreReview> get sortedReviews {
    final sortedList = reviews.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print(
        'Tri des avis effectué, premier avis: ${sortedList.isNotEmpty ? sortedList.first.id : 'Aucun avis'}');
    return sortedList;
  }
}
