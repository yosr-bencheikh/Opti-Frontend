

import 'package:opti_app/data/data_sources/storeReview_data_source.dart';

class StoreReviewRepository {
  final StoreReviewDataSource _dataSource = StoreReviewDataSource();
  
  Future<List<dynamic>> getBoutiqueReviews(String boutiqueId) async {
    return await _dataSource.fetchBoutiqueReviews(boutiqueId);
  }
  
  Future<Map<String, dynamic>> addBoutiqueReview(
      String boutiqueId, String customerId, String reviewText, int rating) async {
    return await _dataSource.submitBoutiqueReview(
        boutiqueId, customerId, reviewText, rating);
  }
  
  Future<Map<String, dynamic>> removeBoutiqueReview(String reviewId, String customerId) async {
    return await _dataSource.deleteBoutiqueReview(reviewId, customerId);
  }
}