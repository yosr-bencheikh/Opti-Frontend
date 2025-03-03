import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/review_data_source.dart';

class ReviewController extends GetxController {
  final ReviewDataSource _dataSource = ReviewDataSource();

  final RxString productId = ''.obs;
  final RxList reviews = [].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Variable to hold the selected review ID
  final RxString selectedReviewId = ''.obs;

  void setProductId(String id) {
    productId.value = id;
    fetchReviews();
  }

  // Helper method to set selected review id safely
  void setSelectedReviewId(dynamic id) {
    selectedReviewId.value = id?.toString() ?? '';
  }

  Future<void> fetchReviews() async {
    if (productId.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final fetchedReviews = await _dataSource.fetchReviews(productId.value);
      reviews.value = fetchedReviews;
    } catch (error) {
      errorMessage.value = 'Failed to load reviews';
      print('Error fetching reviews: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitReview(
      String productId, String userId, String reviewText, int rating) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result =
          await _dataSource.submitReview(productId, userId, reviewText, rating);

      if (result['success']) {
        await fetchReviews(); // Refresh reviews list
        return true;
      } else {
        errorMessage.value = result['error'];
        if (result.containsKey('toxicityScores')) {
          print('Toxicity scores: ${result['toxicityScores']}');
        }
        return false;
      }
    } catch (error) {
      errorMessage.value = 'Failed to submit review';
      print('Error submitting review: $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteReview(dynamic reviewId, String userId) async {
    // Convert reviewId to a non-null string
    final String id = reviewId?.toString() ?? '';
    if (userId.isEmpty) {
      errorMessage.value = 'User not authenticated. Please log in.';
      return false;
    }
    if (id.isEmpty) {
      errorMessage.value = 'Review ID is not provided.';
      return false;
    }
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _dataSource.deleteReview(id, userId);
      if (result['success']) {
        // Refresh reviews list
        await fetchReviews();
        return true;
      } else {
        errorMessage.value = result['error'];
        return false;
      }
    } catch (error) {
      errorMessage.value = 'Failed to delete review';
      print('Error deleting review: $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
