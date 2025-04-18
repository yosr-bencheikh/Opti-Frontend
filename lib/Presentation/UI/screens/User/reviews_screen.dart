import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/Presentation/controllers/review_controller.dart';

class ReviewsScreen extends StatelessWidget {
  final Product product;

  const ReviewsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ReviewController reviewController = Get.put(ReviewController());
    final ProductController productController = Get.find();

    // Set product ID and fetch reviews immediately
    reviewController.setProductId(product.id!);

    // Force refresh product data to ensure we have latest ratings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.forceRefreshProduct(product.id!);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis des clients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewDialog(
            context, reviewController, productController, product),
        child: const Icon(Icons.edit),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOverallRating(product, reviewController, productController),
            Obx(() {
              if (reviewController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (reviewController.reviews.isEmpty) {
                return const Center(child: Text('Aucun avis pour le moment.'));
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviewController.reviews.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final review =
                        reviewController.reviews[index] as Map<String, dynamic>;
                    return _buildReviewItem(
                        context, review, reviewController, productController);
                  },
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Map<String, dynamic> review,
      ReviewController reviewController, ProductController productController) {
    final AuthController authController = Get.find<AuthController>();

    dynamic userIdValue = review['userId'];
    String userId = '';
    if (userIdValue is String) {
      userId = userIdValue;
    } else if (userIdValue is Map<String, dynamic>) {
      userId = userIdValue['_id']?.toString() ?? '';
    }

    return FutureBuilder<UserModel?>(
      future: userId.isNotEmpty
          ? authController.fetchAndStoreUser(userId)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text("Erreur lors de la récupération de l'utilisateur"));
        } else {
          final reviewUser = snapshot.data;
          final String userName = reviewUser != null
              ? '${reviewUser.nom} ${reviewUser.prenom}'
              : 'Unknown User';
          final String userImageUrl =
              reviewUser?.imageUrl ?? 'https://i.pravatar.cc/50';

          final String relativeTime = _getRelativeTime(review['timestamp']);
          final dynamic reviewIdValue = review['id'] ??
              review['reviewId'] ??
              review['review_id'] ??
              review['_id'];
          final String reviewId = reviewIdValue?.toString() ?? '';

          return GestureDetector(
            onLongPress: () {
              if (reviewId.isEmpty) {
                print("Review ID is missing; cannot delete.");
                return;
              }
              reviewController.setSelectedReviewId(reviewId);
              _showDeleteConfirmation(context, reviewId, reviewController,
                  productController, product.id!);
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
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      String reviewId,
      ReviewController reviewController,
      ProductController productController,
      String productId) {
    final AuthController authController = Get.find<AuthController>();

    // Make sure we're getting a String, not an RxString
    final String userId = authController.currentUserId is RxString
        ? (authController.currentUserId as RxString).value
        : authController.currentUserId.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer l'avis"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cet avis ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                if (userId.isEmpty) {
                  Navigator.pop(context);
                  return;
                }

                bool success =
                    await reviewController.deleteReview(reviewId, userId);

                if (success) {
                  // First refresh reviews without parameter
                  await reviewController.fetchReviews();

                  // Then calculate new ratings
                  double newAvgRating = 0.0;
                  int newTotalReviews = reviewController.reviews.length;

                  if (newTotalReviews > 0) {
                    double totalRating = 0.0;
                    for (var review in reviewController.reviews) {
                      totalRating += (review['rating'] as int).toDouble();
                    }
                    newAvgRating = totalRating / newTotalReviews;
                  }

                  // Update database with new ratings
                  await reviewController.updateProductRatings(
                    productId,
                    newAvgRating,
                    newTotalReviews,
                  );

                  // Force refresh product data after deletion
                  await productController.forceRefreshProduct(productId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Avis supprimé")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Échec de la suppression de l'avis")),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Supprimer"),
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

  Widget _buildOverallRating(Product product, ReviewController reviewController,
      ProductController productController) {
    return Obx(() {
      final reviews = reviewController.reviews;
      double averageRating = 0.0;
      int totalReviews = reviews.length;

      if (totalReviews > 0) {
        double totalRating = 0.0;
        for (var review in reviews) {
          totalRating += (review['rating'] as int).toDouble();
        }
        averageRating = totalRating / totalReviews;
      }

      // Update all product instances with new ratings and save to database
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Update local state first
        productController.updateProductRating(
          product.id!,
          averageRating,
          totalReviews,
        );

        // Then update the database
        reviewController
            .updateProductRatings(
          product.id!,
          averageRating,
          totalReviews,
        )
            .then((success) {
          if (!success) {
            print('Failed to save ratings to database');
          }
        });
      });

      // Rest of the method stays the same...
      Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var review in reviews) {
        int rating = review['rating'] as int;
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }

      return Container(
        // The existing UI code...
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
    });
  }

  void _showReviewDialog(
    BuildContext context,
    ReviewController reviewController,
    ProductController productController,
    Product product,
  ) {
    final TextEditingController _reviewTextController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxString errorMessage = ''.obs;
    final AuthController _authController = Get.find<AuthController>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Écrire un avis"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reviewTextController,
                    decoration: const InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Évaluation :',
                            style: TextStyle(fontSize: 16)),
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
                  Obx(() => errorMessage.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            errorMessage.value,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (_reviewTextController.text.isNotEmpty &&
                      rating.value > 0) {
                    final userId = _authController.currentUserId.value;
                    errorMessage.value = '';

                    try {
                      bool success = await reviewController.submitReview(
                        product.id!,
                        userId,
                        _reviewTextController.text,
                        rating.value,
                      );

                      if (success) {
                        // First refresh reviews without parameter
                        await reviewController.fetchReviews();

                        // Then calculate new ratings
                        double newAvgRating = 0.0;
                        int newTotalReviews = reviewController.reviews.length;

                        if (newTotalReviews > 0) {
                          double totalRating = 0.0;
                          for (var review in reviewController.reviews) {
                            totalRating += (review['rating'] as int).toDouble();
                          }
                          newAvgRating = totalRating / newTotalReviews;
                        }

                        // Update database
                        await reviewController.updateProductRatings(
                          product.id!,
                          newAvgRating,
                          newTotalReviews,
                        );

                        // Force refresh product data after submission
                        await productController
                            .forceRefreshProduct(product.id!);
                        Navigator.pop(context);
                      } else {
                        errorMessage.value =
                            reviewController.errorMessage.value.toString();
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
                child: const Text('Soumettre'),
              ),

// And update the delete confirmation handler:
            ],
          );
        },
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
}
