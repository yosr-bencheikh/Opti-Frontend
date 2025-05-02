import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/storeReview_controller.dart';
import 'package:opti_app/data/models/user_model.dart';

import 'package:opti_app/domain/entities/StoreReview.dart';

// -----------------------------------------------------------------------
// Reviews Screen using StoreReviewController to load data from the database
// -----------------------------------------------------------------------
class OpticianReviewsScreen extends StatelessWidget {
  final String boutiqueId;

  const OpticianReviewsScreen({Key? key, required this.boutiqueId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the repository from GetX dependency injection and create the controller.
    // Ensure you have registered StoreReviewRepository via Get.put() (or Get.lazyPut()) at app start.
    final StoreReviewController controller = Get.find();

    // Load reviews for the boutique; consider calling this only once (e.g. in initState)
    controller.loadReviews(boutiqueId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Avis et évaluations'),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Text(
              'Erreur: ${controller.error.value}',
              style: GoogleFonts.montserrat(color: Colors.red),
            ),
          );
        }

        final int totalReviews = controller.reviews.length;
        double avgRating = controller.averageRating;
        final Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

        for (var review in controller.reviews) {
          ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
        }

        return Column(
          children: [
            _buildRatingSummary(avgRating, ratingCounts, totalReviews),
            Expanded(
              child: totalReviews == 0
                  ? Center(
                      child: Text(
                        'Aucun avis pour le moment',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: controller.sortedReviews.length,
                      itemBuilder: (context, index) {
                        final review = controller.sortedReviews[index];
                        return _buildReviewCard(review);
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddReviewScreen(boutiqueId: boutiqueId));
        },
        child: Icon(Icons.rate_review),
        tooltip: 'Ajouter un avis',
      ),
    );
  }

  Widget _buildRatingSummary(
      double averageRating, Map<int, int> ratingCounts, int totalReviews) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : index < averageRating
                              ? Icons.star_half
                              : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  '$totalReviews avis',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final starLevel = 5 - index;
                final count = ratingCounts[starLevel] ?? 0;
                final percentage =
                    totalReviews == 0 ? 0.0 : count / totalReviews;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$starLevel'),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('$count'),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(StoreReview review) {
   
    final authController = Get.find<AuthController>();

    // Extract userId similar to _buildReviewItem
    dynamic userIdValue = review.customerId;
    String userId = '';
    if (userIdValue is String) {
      userId = userIdValue;
    } else if (userIdValue is Map<String, dynamic>) {
      userId = userIdValue['_id']?.toString() ?? '';
    } else if (userIdValue != null) {
      // Handle the case when customerId is an object with an id property
      userId = userIdValue.id?.toString() ?? '';
    }

    print("Building review card for user with ID: $userId");

    return FutureBuilder<UserModel?>(
      future: userId.isNotEmpty
          ? authController.fetchAndStoreUser(userId)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else {
          final reviewUser = snapshot.data;
          final String userName = reviewUser != null
              ? '${reviewUser.nom} ${reviewUser.prenom}'
              : 'Unknown User';
          final String userImageUrl =
              reviewUser?.imageUrl ?? 'https://i.pravatar.cc/50';

          final bool isCurrentUserOwner =
              authController.currentUser?.id == userId;

          return GestureDetector(
            onLongPress: isCurrentUserOwner
                ? () => _showDeleteConfirmationDialog(review.id, userId)
                : null,
            child: Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // User Image
                              CircleAvatar(
                                backgroundImage: NetworkImage(userImageUrl),
                                radius: 20,
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  print("Error loading image: $exception");
                                },
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userName,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(review.timestamp),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => _buildStarIcon(index, review.rating),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      review.reviewText,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey.shade800,
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

  Widget _buildStarIcon(int index, int rating) {
    return Icon(
      index < rating ? Icons.star : Icons.star_border,
      color: Colors.amber,
      size: 20,
    );
  }

  void _showDeleteConfirmationDialog(String reviewId, String customerId) {
    Get.defaultDialog(
      title: 'Confirmation',
      titleStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      middleText: 'Voulez-vous vraiment supprimer cet avis ?',
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
        ),
        onPressed: () async {
          Get.back();
          final success = await Get.find<StoreReviewController>()
              .deleteReview(reviewId, customerId);
          if (success) {
            Get.snackbar(
              'Succès',
              'Avis supprimé avec succès',
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );
          }
        },
        child: Text('Supprimer', style: GoogleFonts.montserrat()),
      ),
      cancel: TextButton(
        onPressed: Get.back,
        child: Text('Annuler', style: GoogleFonts.montserrat()),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// -----------------------------------------------------------------------
// Add Review Screen: Boutique Review Submission with Logging and Null-Check
// -----------------------------------------------------------------------
class AddReviewScreen extends StatefulWidget {
  final String boutiqueId;

  const AddReviewScreen({Key? key, required this.boutiqueId}) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 0;
  // Name is retrieved from AuthController; no text controller needed.
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un avis'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Center(
              child: Text(
                'Comment évaluez-vous ce magasin?',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Star rating selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16),
            // Review comment input
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Votre avis',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre avis';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            // Submit button with logging
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Soumettre'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0) {
        Get.snackbar(
          'Erreur',
          'Veuillez attribuer une note',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Log entry for debugging
        print(
            'Tentative de soumission de l\'avis pour boutique: ${widget.boutiqueId}');
        print('Rating: $_rating, Commentaire: ${_commentController.text}');

        // Retrieve the StoreReviewController.
        final StoreReviewController reviewController =
            Get.find<StoreReviewController>();
        // Retrieve the AuthController.
        final AuthController authController = Get.find<AuthController>();

        // If currentUser is null, attempt to load it from shared preferences.
        if (authController.currentUser == null) {
          print('Current user is null, attempting to load from prefs...');
          // You should have stored the email during login (or use currentUserId if available)
          final String? storedEmail =
              authController.prefs.getString('userEmail');
          if (storedEmail != null && storedEmail.isNotEmpty) {
            await authController.loadUserData(storedEmail);
            print(
                'User loaded from prefs. currentUser: ${authController.currentUser}');
          }
        }

        // Double-check after loading
        final currentUser = authController.currentUser;
        if (currentUser == null) {
          // If still null, show an error
          print('Erreur: currentUser is still null after attempting to load.');
          Get.snackbar(
            'Erreur',
            'Utilisateur non connecté. Veuillez vous reconnecter.',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          return;
        }

        print('Utilisateur trouvé: ${currentUser.nom} ${currentUser.prenom}');

        // Retrieve user details.
        final String? customerId = currentUser.id;
        final String customerName = '${currentUser.nom} ${currentUser.prenom}';

        // Submit the review via the controller.
        bool success = await reviewController.addReview(
          boutiqueId: widget.boutiqueId,
          customerId: customerId ?? '',
          reviewText: _commentController.text,
          rating: _rating,
          customerName: customerName,
        );

        if (success) {
          print('Avis soumis avec succès.');
          Get.back();
          Get.snackbar(
            'Succès',
            'Votre avis a bien été ajouté',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        } else {
          print('Échec de la soumission de l\'avis.');
          Get.snackbar(
            'Erreur',
            'Échec de l\'ajout de l\'avis',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        }
      } catch (e, stackTrace) {
        print('Exception lors de la soumission de l\'avis: $e');
        print(stackTrace);
        Get.snackbar(
          'Erreur',
          'Une erreur est survenue: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
