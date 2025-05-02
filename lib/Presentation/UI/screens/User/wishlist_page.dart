import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/core/styles/colors.dart';

class WishlistPage extends StatelessWidget {
  final String userEmail;
  final ProductController productController = Get.find();
  final AuthController authController = Get.find<AuthController>();

  WishlistPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.find();
    controller.initUser(userEmail);

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
     appBar: AppBar(
        title: Text(
          'Liste de souhaits',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 233, 234, 239),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.whiteColor),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 221, 226, 239),
                AppColors.secondaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.whiteColor,
              Color.lerp(AppColors.whiteColor, AppColors.softWhite, 0.5)!,
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de votre liste...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.greyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.wishlistItems.isEmpty) {
            return _buildEmptyWishlist();
          }

          return _buildWishlistContent(controller, context);
        }),
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.8), 
                    AppColors.accentColor
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.softBlue.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: AppColors.whiteColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Votre liste de souhaits est vide',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ajoutez des articles à votre liste pour les retrouver facilement plus tard',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.greyTextColor,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Get.to(() => StoresScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.whiteColor,
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
                shadowColor: AppColors.secondaryColor.withOpacity(0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Découvrir les produits',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(WishlistController controller, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: controller.wishlistItems.length,
      itemBuilder: (context, index) {
        final wishlistItem = controller.wishlistItems[index];
        final product = productController.products.firstWhereOrNull(
              (p) => p.id == wishlistItem.productId,
            ) ??
            Product(
              id: 'not_found',
              name: 'Produit non disponible',
              prix: 0,
              image: '',
              description: '',
              category: '',
              marque: '',
              couleur: ['0000'],
              quantiteStock: 0,
              averageRating: 0,
              totalReviews: 0,
              style: '',
              model3D: '',
              materiel: '',
              sexe: '',
            );

        if (product.id == 'not_found') return const SizedBox.shrink();

        // Normaliser l'URL du modèle 3D
        String normalizedModelUrl = product.model3D.isNotEmpty
            ? _normalizeModelUrl(product.model3D)
            : '';

        final bool has3DModel = product.model3D.isNotEmpty;

        return Dismissible(
          key: Key('${wishlistItem.productId}_${product.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.accentColor,
              size: 28,
            ),
          ),
          onDismissed: (direction) async {
            final removedItem = controller.wishlistItems[index];
            controller.wishlistItems.removeAt(index);

            try {
              await controller.removeFromWishlist(product.id!);
              Get.snackbar(
                'Supprimé',
                'Article retiré de la liste',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primaryColor.withOpacity(0.9),
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 10,
                duration: const Duration(seconds: 2),
                icon: Icon(Icons.check_circle_outline, color: Colors.white),
              );
            } catch (e) {
              if (index <= controller.wishlistItems.length) {
                controller.wishlistItems.insert(index, removedItem);
              } else {
                controller.wishlistItems.add(removedItem);
              }
              Get.snackbar(
                'Erreur',
                'Échec de la suppression de l\'article',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.accentColor,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 10,
                icon: Icon(Icons.error_outline, color: Colors.white),
              );
            }
          },
          child: GestureDetector(
            onTap: () => product.id != 'not_found'
                ? Get.to(() => ProductDetailsScreen(product: product))
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: AppColors.secondaryColor.withOpacity(0.1),
                    highlightColor: AppColors.accentColor.withOpacity(0.05),
                    onTap: () => product.id != 'not_found'
                        ? Get.to(() => ProductDetailsScreen(product: product))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.softWhite,
                              border: Border.all(
                                color: AppColors.paleBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: has3DModel
                                  ? FutureBuilder<bool>(
                                      future: _checkModelAvailability(normalizedModelUrl),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                              child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                AppColors.secondaryColor),
                                          ));
                                        }

                                        if (snapshot.hasData &&
                                            snapshot.data == true) {
                                          return Stack(
                                            children: [
                                              Flutter3DViewer(
                                                src: normalizedModelUrl,
                                              ),
                                              Positioned(
                                                top: 5,
                                                right: 5,
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.secondaryColor.withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Icon(
                                                    Icons.view_in_ar,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          // Fallback à l'image si le modèle n'est pas disponible
                                          return product.image.isNotEmpty
                                              ? Image.network(
                                                  product.image,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child,
                                                      loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<Color>(
                                                                AppColors.secondaryColor),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (context, error, stackTrace) =>
                                                          Center(
                                                    child: Icon(
                                                      Icons.broken_image_rounded,
                                                      color: AppColors.greyTextColor,
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(Icons.image_rounded,
                                                      color: AppColors.greyTextColor));
                                        }
                                      },
                                    )
                                  : product.image.isEmpty
                                      ? Icon(Icons.image_rounded, color: AppColors.greyTextColor)
                                      : Image.network(
                                          product.image,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        AppColors.secondaryColor),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) => Container(
                                            color: AppColors.softWhite,
                                            child: Icon(Icons.broken_image_rounded,
                                                color: AppColors.greyTextColor),
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppColors.accentColor,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await controller
                                              .removeFromWishlist(product.id!);
                                        } catch (e) {
                                          Get.snackbar(
                                            'Erreur',
                                            'Échec de la suppression de l\'article',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppColors.accentColor,
                                            colorText: Colors.white,
                                          );
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (product.marque.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      product.marque,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.greyTextColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '€${product.prix.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                    if (product.quantiteStock > 0)
                                      Container(
                                        margin: EdgeInsets.only(left: 10),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (product.quantiteStock > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          'En stock',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.greyTextColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _addToCart(product, context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 38),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Ajouter au panier',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart(Product product, BuildContext context) async {
    final cartController = Get.find<CartItemController>();
    final userId = authController.currentUserId.value;
    
    if (userId.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez vous connecter pour ajouter des articles au panier',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await cartController.createCartItem(
        userId: userId,
        productId: product.id!,
        quantity: 1, // Quantité par défaut
        totalPrice: product.prix, // Prix pour 1 article
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Article ajouté au panier',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: AppColors.secondaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Échec de l\'ajout de l\'article au panier',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: AppColors.accentColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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

  String _normalizeModelUrl(String url) {
    // Implémentez votre logique de normalisation d'URL ici
    return GlassesManagerService.ensureAbsoluteUrl(url);
  }
}