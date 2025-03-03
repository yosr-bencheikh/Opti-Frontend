import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/camera_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/home_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/reviews_screen.dart';

class ProductDetailsScreen extends GetView<ProductController> {
  final Product product;

  ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  // These should be moved to a controller or initialized properly
  final RxBool isInWishlist = false.obs;
  final RxBool isCheckingWishlist = true.obs;
  final RxBool showArAnimation =
      true.obs; // Pour contrôler l'animation du bouton AR

  @override
  Widget build(BuildContext context) {
    // Move initialization logic to initState or onInit of a StatefulWidget
    // or to a controller's onInit
    _initializeData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Sticky Image Section avec bouton AR superposé
          SliverAppBar(
            expandedHeight: 300, // Height of the image when expanded
            pinned: true, // Make the image stick to the top
            flexibleSpace: Stack(
              children: [
                FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: product.image.isNotEmpty
                        ? Container(
                            width: double.infinity,
                            height: 300,
                            child: Image.network(
                              product.image,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            child: Icon(Icons.image,
                                size: 100, color: Colors.grey),
                          ),
                  ),
                ),
                // Bouton AR en superposition
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildARButton(context),
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
                _buildProductSpecs(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
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
            color: Colors.blue[600],
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'En stock',
                  style: TextStyle(
                    color: Colors.green[700],
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
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSpecs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spécifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildSpecRow('Marque', product.marque),
                const Divider(),
                _buildSpecRow('Catégorie', product.category),
                const Divider(),
                _buildSpecRow('Référence', product.id ?? 'Non spécifié'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Rating Section
  Widget _buildRatingSection() {
    return GestureDetector(
      onTap: () => Get.to(() => ReviewsScreen(product: product)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 4),
            Text(
              ' ${product.averageRating.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
            SizedBox(width: 4),
            Text(
              ' (${product.totalReviews} reviews)',
              style: TextStyle(color: Colors.grey),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
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
              blurRadius: 10,
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
                  color: isInWishlist.value ? Colors.red : Colors.grey,
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
                onPressed: () {
                  if (product.id == null || product.id!.isEmpty) {
                    Get.snackbar('Error', 'Invalid product data');
                    return;
                  }
                  // Make sure you have access to context here
                  showProductDialog(context, product);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[80],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ajouter au panier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
