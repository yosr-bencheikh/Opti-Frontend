import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';

import 'package:opti_app/Presentation/UI/screens/User/Face_detection.dart';

import 'package:opti_app/Presentation/UI/screens/User/home_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/reviews_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';

// Import your color palette class


class ProductDetailsScreen extends GetView<ProductController> {
  final Product product;

  ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  // These should be moved to a controller or initialized properly
  final RxBool isInWishlist = false.obs;
  final RxBool isCheckingWishlist = true.obs;
  final RxBool showArAnimation =
      true.obs; // Pour contrôler l'animation du bouton AR
  final RxBool show3DModelView = false.obs;
  // Normaliser l'URL du modèle 3D
  String get normalizedModelUrl => product.model3D.isNotEmpty
      ? _normalizeModelUrl(product.model3D)
      : ''; // To control whether to show 3D view

  @override
  Widget build(BuildContext context) {
    // Move initialization logic to initState or onInit of a StatefulWidget
    // or to a controller's onInit
    _initializeData();

    return Scaffold(
      backgroundColor: Colors.white, // Keep the background white as requested
      body: CustomScrollView(
        slivers: [
          // Sticky Image Section avec bouton AR superposé
          SliverAppBar(
            expandedHeight: 300, // Height of the image when expanded
            pinned: true, // Make the image stick to the top
            backgroundColor: const Color.fromARGB(255, 202, 221, 242).withOpacity(0.4),// Changed to your secondary color
            flexibleSpace: Stack(
              children: [
                FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      product.model3D.isNotEmpty
                          ? FutureBuilder<bool>(
                              future:
                                  _checkModelAvailability(normalizedModelUrl),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.accentColor, // Changed to accent color
                                      ));
                                }

                                if (snapshot.hasData && snapshot.data == true) {
                                  return Flutter3DViewer(src: product.model3D);
                                } else {
                                  // Fallback à l'image si le modèle n'est pas disponible
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.softWhite, // Changed to soft white
                                    ),
                                    child: product.image.isNotEmpty
                                        ? Image.network(
                                            product.image,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Center(
                                            child: Icon(Icons.image,
                                                size: 100, color: AppColors.greyTextColor), // Changed to grey text color
                                          ),
                                  );
                                }
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.softWhite, // Changed to soft white
                              ),
                              child: product.image.isNotEmpty
                                  ? Image.network(
                                      product.image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Center(
                                      child: Icon(Icons.image,
                                          size: 100, color: AppColors.greyTextColor), // Changed to grey text color
                                    ),
                            ),
                      if (product.model3D.isNotEmpty)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.6), // Changed to primary color
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Vue 3D active",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Bouton AR en superposition
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildARButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                _buildProductDescription(),
                _buildProductSpecs(context), // Pass context here
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Vérifiez la disponibilité du modèle 3D
  Future<bool> _checkModelAvailability(String url) async {
    if (url.isEmpty) return false;

    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur de vérification du modèle 3D: $e');
      return false;
    }
  }

  // Normalisation de l'URL
  String _normalizeModelUrl(String url) {
    // Utilisation du service comme dans OpticianProductsScreen
    return GlassesManagerService.ensureAbsoluteUrl(url);
  }

  Widget _buildARButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildARButton(context),
      ],
    );
  }

  void _initializeData() {
    // Check if this has already been initialized to prevent multiple calls
    if (isCheckingWishlist.value) {
      _checkWishlistStatus();

      final AuthController authController = Get.find<AuthController>();
      final WishlistController wishlistController =
          Get.find<WishlistController>();

      if (authController.currentUser?.email != null) {
        if (wishlistController.currentUserEmail !=
            authController.currentUser!.email) {
          wishlistController.initUser(authController.currentUser!.email);
        }
      }

      // Pour arrêter l'animation après quelques secondes
      Future.delayed(const Duration(seconds: 5), () {
        showArAnimation.value = false;
      });
    }
  }

  Future<void> _checkWishlistStatus() async {
    final WishlistController wishlistController =
        Get.find<WishlistController>();
    final AuthController authController = Get.find<AuthController>();

    isCheckingWishlist.value = true;

    if (authController.currentUser?.email != null) {
      // Vérifier si l'utilisateur est déjà initialisé
      if (wishlistController.currentUserEmail !=
          authController.currentUser!.email) {
        // Initialiser l'utilisateur et attendre que ce soit terminé
        wishlistController.initUser(authController.currentUser!.email);
        // Attendre un court instant pour que l'initialisation se fasse
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Vérifier si le produit est dans la wishlist
      try {
        // Option plus robuste: vérifier en temps réel
        final bool inWishlist = await wishlistController
            .checkProductInWishlistRealtime(product.id!);
        isInWishlist.value = inWishlist;
      } catch (e) {
        // En cas d'erreur, utiliser la méthode locale
        isInWishlist.value =
            wishlistController.isProductInWishlist(product.id!);
      }
    }

    isCheckingWishlist.value = false;
  }

  // Nouveau widget pour le bouton AR avec animation
  Widget _buildARButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      transform: showArAnimation.value
          ? Matrix4.identity()
          : Matrix4.translationValues(0, -5, 0),
      child: GestureDetector(
        onTap: () {
          _launchARExperience(context);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentColor, // Changed to accent color
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: showArAnimation.value
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_in_ar_rounded,
                color: Colors.white,
                size: 24,
              ),
              if (showArAnimation.value) ...[
                const SizedBox(width: 8),
                Text(
                  "Essayez en AR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _launchARExperience(BuildContext context) {
    try {
      print("Starting navigation to FaceDetectionScreen");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FaceDetectionScreen()),
      ).then((_) {
        print("Successfully returned from FaceDetectionScreen");
      });
      print("Navigation code executed");
    } catch (e) {
      print("Error during navigation: $e");
      // You could also show an error dialog here
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Navigation Error"),
          content: Text("Failed to open face detection: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor, // Changed to primary color
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor, // Changed to text color
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              _buildRatingSection(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '€${product.prix.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor, // Changed to primary color
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFECFDF5), // Light green background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'En stock',
                  style: TextStyle(
                    color: Color(0xFF047857), // Dark green text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor, // Changed to text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyTextColor, // Changed to grey text color
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Pass the BuildContext parameter here
  Widget _buildProductSpecs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spécifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor, // Changed to text color
            ),
          ),
          const SizedBox(height: 12),
          Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white, // Blanc pur comme dans OpticianProductsScreen
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.paleBlue.withOpacity(0.3)),
  ),
            child: Column(
              children: [
                _buildSpecRow('Marque', product.marque),
                const Divider(),
                _buildSpecRow('Catégorie', product.category),
                const Divider(),
                _buildSpecRow('Référence', product.id ?? 'Non spécifié'),
                const Divider(),
                // Now we need to use context in the onTap callback
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mettez à jour _buildSpecRow pour gérer le cas spécial et l'interaction
  Widget _buildSpecRow(String label, String value,
      {bool special = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyTextColor, // Changed to grey text color
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: special ? AppColors.accentViolet : AppColors.textColor, // Changed to accent violet for special, text color for normal
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accentViolet), // Changed to accent violet
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rating Section: Updated to fetch real-time values from ProductController
  Widget _buildRatingSection() {
    // Get the product controller
    final ProductController productController = Get.find<ProductController>();
    return GestureDetector(
      onTap: () => Get.to(() => ReviewsScreen(product: product)),
      child: Obx(() {
        // Look up the updated product in the controller's products list.
        // If not found, fall back to the passed product instance.
        final updatedProduct = productController.products.firstWhere(
          (p) => p.id == product.id,
          orElse: () => product,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFFFEF3C7), // Light amber color
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFD97706), size: 20), // Amber color
              const SizedBox(width: 4),
              Text(
                ' ${updatedProduct.averageRating.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309), // Dark amber
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ' (${updatedProduct.totalReviews} avis)',
                style: TextStyle(color: AppColors.greyTextColor), // Changed to grey text color
              ),
              Icon(Icons.chevron_right, color: AppColors.greyTextColor, size: 20), // Changed to grey text color
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    final WishlistController wishlistController =
        Get.find<WishlistController>();
    final AuthController authController = Get.find<AuthController>();

    return Builder(builder: (BuildContext context) {
      // Add this Builder widget to get context
      return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        spreadRadius: 1,
        blurRadius: 5,
        offset: Offset(0, -2),
      ),
    ],
  ),
        child: Row(
          children: [
            Obx(() {
              // Utilisez isInWishlist.value plutôt que d'appeler directement wishlistController
              return IconButton(
                icon: Icon(
                  isInWishlist.value ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist.value ? Colors.red : AppColors.greyTextColor, // Changed to grey text color when not favorite
                  size: 28,
                ),
                onPressed: () async {
                  final userEmail = authController.currentUser?.email;
                  if (userEmail == null) {
                    Get.snackbar('Erreur', 'Veuillez vous connecter d\'abord');
                    return;
                  }

                  try {
                    if (isInWishlist.value) {
                      // Si produit est dans la liste de souhaits, le supprimer
                      final wishlistItem = wishlistController
                          .getWishlistItemByProductId(product.id!);
                      if (wishlistItem != null) {
                        await wishlistController
                            .removeFromWishlist(product.id!);
                        isInWishlist.value =
                            false; // Mettre à jour l'état local immédiatement
                      }
                    } else {
                      // Si produit n'est pas dans la liste de souhaits, l'ajouter
                      final wishlistItem = WishlistItem(
                        // ID sera généré côté serveur
                        userId: userEmail,
                        productId: product.id!,
                      );
                      await wishlistController.addToWishlist(wishlistItem);
                      isInWishlist.value =
                          true; // Mettre à jour l'état local immédiatement
                    }
                    // Rafraîchir l'état après l'opération
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      'Impossible de mettre à jour la liste de souhaits',
                      backgroundColor: Colors.red[100],
                      colorText: Colors.red[900],
                    );
                  }
                },
              );
            }),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: product.quantiteStock == 0
                    ? null // Disable the button when the quantity is 0
                    : () {
                        if (product.id == null || product.id!.isEmpty) {
                          Get.snackbar('Erreur', 'Données produit invalides');
                          return;
                        }
                        // Show product dialog
                        showProductDialog(context, product);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.quantiteStock == 0
                      ? Colors.grey[300] // Change the button color when disabled
                      : AppColors.primaryColor, // Changed to primary color
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  product.quantiteStock == 0
                      ? 'Rupture de stock'
                      : 'Ajouter au panier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: product.quantiteStock == 0
                        ? Colors.red
                        : Colors.white, // Changed to white for better contrast
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}