import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/data_sources/review_data_source.dart';

class ReviewController extends GetxController {
  final ReviewDataSource _dataSource = ReviewDataSource();
  final ProductController _productController = Get.find<ProductController>();

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
        // After successful submission, recalculate and update the ratings
        await fetchReviews(); // Refresh the reviews list first
        await _updateProductRatingsFromReviews(productId);
        
        // Update the product state
        await _productController.fetchProductRatingAndReviews(productId);
        await _productController.loadProducts(); // Refresh all products
        return true;
      } else {
        errorMessage.value = result['error'].toString();
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
    final String id =
        reviewId is RxString ? reviewId.value : reviewId.toString();

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
        // After successful deletion, recalculate and update the ratings
        await fetchReviews(); // Refresh the reviews list first
        await _updateProductRatingsFromReviews(productId.value);
        
        // Update the product state
        await _productController.fetchProductRatingAndReviews(productId.value);
        await _productController.loadProducts();
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

  // Method to update product ratings in the database
  Future<bool> updateProductRatings(String productId, double averageRating, int totalReviews) async {
    try {
      final result = await _dataSource.updateProductRatings(productId, averageRating, totalReviews);
      return result['success'] == true;
    } catch (e) {
      print('Error in updateProductRatings: $e');
      return false;
    }
  }
  
  // Helper method to calculate and update ratings from current reviews
  Future<bool> _updateProductRatingsFromReviews(String productId) async {
    if (reviews.isEmpty) {
      // If no reviews, set ratings to 0
      return await updateProductRatings(productId, 0.0, 0);
    }
    
    int totalReviews = reviews.length;
    double totalRating = 0.0;
    
    for (var review in reviews) {
      totalRating += (review['rating'] as int).toDouble();
    }
    
    double averageRating = totalRating / totalReviews;
    return await updateProductRatings(productId, averageRating, totalReviews);
  }
}