import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/Presentation/controllers/review_controller.dart';

class ReviewsScreen extends StatelessWidget {
  final Product product;

  const ReviewsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Initialize (or retrieve) the ReviewController
    final ReviewController reviewController = Get.put(ReviewController());

    // Set the product ID and fetch reviews when the screen is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (reviewController.productId.value != product.id) {
        reviewController.setProductId(product.id!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewDialog(context, reviewController),
        child: const Icon(Icons.edit),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Obx(() => _buildOverallRating(product, reviewController)),
          Expanded(
            child: Obx(() {
              if (reviewController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (reviewController.reviews.isEmpty) {
                return const Center(child: Text('No reviews yet.'));
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviewController.reviews.length,
                  itemBuilder: (context, index) {
                    final review =
                        reviewController.reviews[index] as Map<String, dynamic>;
                    return _buildReviewItem(context, review);
                  },
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Map<String, dynamic> review) {
    final ReviewController reviewController = Get.find<ReviewController>();
    final AuthController authController = Get.find<AuthController>();

    final User? currentUser = authController.currentUser;
    final String userName = currentUser != null
        ? '${currentUser.nom} ${currentUser.prenom}'
        : 'Unknown User';
    final String userImageUrl =
        currentUser?.imageUrl ?? 'https://i.pravatar.cc/50';

    final String relativeTime = _getRelativeTime(review['timestamp']);

    // Try to obtain the review ID using several possible keys.
    final dynamic reviewIdValue = review['id'] ??
        review['reviewId'] ??
        review['review_id'] ??
        review['_id'];
    final String reviewId = reviewIdValue?.toString() ?? '';

    if (reviewId.isEmpty) {
      print("Review data keys: ${review.keys}");
      print("Review ID is missing; cannot delete.");
    }

    return GestureDetector(
      onLongPress: () {
        if (reviewId.isEmpty) {
          print("Review ID is missing; cannot delete.");
          return;
        }
        // Update the controller with the selected review ID.
        reviewController.setSelectedReviewId(reviewId);
        // Show the delete confirmation dialog.
        _showDeleteConfirmation(context, reviewId);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userImageUrl),
                ),
                title: Text(userName),
                subtitle: Text(relativeTime),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    review['rating'],
                    (index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  review['reviewText'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String reviewId) {
    final AuthController authController = Get.find<AuthController>();
    final String? userId = authController.currentUserId.value;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Review"),
          content: const Text("Are you sure you want to delete this review?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (userId == null || userId.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                bool success = await Get.find<ReviewController>()
                    .deleteReview(reviewId, userId);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review deleted")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to delete review")),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  String _getRelativeTime(String timestamp) {
    DateTime reviewTime;
    try {
      reviewTime = DateTime.parse(timestamp);
    } catch (e) {
      return timestamp;
    }
    final now = DateTime.now();
    final difference = now.difference(reviewTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }

  void _showReviewDialog(
      BuildContext context, ReviewController reviewController) {
    final TextEditingController _reviewTextController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxString errorMessage = ''.obs;

    // Retrieve the AuthController
    final AuthController _authController = Get.find<AuthController>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Write a Review"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reviewTextController,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rating:', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [1, 2, 3, 4, 5]
                                  .map((starValue) => InkWell(
                                        onTap: () {
                                          rating.value = starValue;
                                        },
                                        child: Icon(
                                          starValue <= rating.value
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 32,
                                        ),
                                      ))
                                  .toList(),
                            )),
                      ],
                    ),
                  ),
                  // Display error message if there is one
                  Obx(() => errorMessage.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            errorMessage.value,
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : SizedBox.shrink()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_reviewTextController.text.isNotEmpty &&
                      rating.value > 0) {
                    // Use the userId from AuthController
                    final userId = _authController.currentUserId.value;
                    // Clear any previous error message
                    errorMessage.value = '';

                    try {
                      // Submit the review and get the result
                      bool success = await reviewController.submitReview(
                        product.id!,
                        userId,
                        _reviewTextController.text,
                        rating.value,
                      );

                      if (success) {
                        Navigator.pop(context);
                      } else {
                        // Update the local error message with the controller's error
                        errorMessage.value =
                            reviewController.errorMessage.value;
                      }
                    } catch (e) {
                      errorMessage.value = 'Failed to submit review: $e';
                    }
                  } else {
                    errorMessage.value =
                        'Please enter a review and select a rating.';
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallRating(
      Product product, ReviewController reviewController) {
    // Calculate average rating and total reviews manually
    double averageRating = 0.0;
    int totalReviews = reviewController.reviews.length;

    if (totalReviews > 0) {
      int sum = 0;
      for (var review in reviewController.reviews) {
        sum += review['rating'] as int;
      }
      averageRating = sum / totalReviews;
    }

    // Update the product's fields with the calculated values
    // Only update if they're not matching (to avoid unnecessary updates)
    if (product.averageRating != averageRating) {
      product.averageRating = averageRating;
    }

    if (product.totalReviews != totalReviews) {
      product.totalReviews = totalReviews;
    }

    // Calculate rating distribution
    Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in reviewController.reviews) {
      int rating = review['rating'] as int;
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < averageRating.floor()
                        ? Icons.star
                        : (index < averageRating)
                            ? Icons.star_half
                            : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              Text(
                '$totalReviews reviews',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildRatingProgress('5',
                    totalReviews > 0 ? ratingCounts[5]! / totalReviews : 0),
                _buildRatingProgress('4',
                    totalReviews > 0 ? ratingCounts[4]! / totalReviews : 0),
                _buildRatingProgress('3',
                    totalReviews > 0 ? ratingCounts[3]! / totalReviews : 0),
                _buildRatingProgress('2',
                    totalReviews > 0 ? ratingCounts[2]! / totalReviews : 0),
                _buildRatingProgress('1',
                    totalReviews > 0 ? ratingCounts[1]! / totalReviews : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingProgress(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(stars),
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: Colors.amber,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // Function to calculate relative time
}
