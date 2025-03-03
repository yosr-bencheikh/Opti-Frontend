
import 'package:opti_app/data/data_sources/review_data_source.dart';

class ReviewRepository {
  final ReviewDataSource _dataSource = ReviewDataSource();

  Future<List<dynamic>> getReviews(String productId) async {
    return await _dataSource.fetchReviews(productId);
  }

  Future<void> addReview(String productId, String userId, String reviewText, int rating) async {
    await _dataSource.submitReview(productId, userId, reviewText, rating);
  }
}