import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Product3DViewer.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart'; // Make sure to import your stores screen
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class WishlistPage extends StatelessWidget {
  final String userEmail;
  final ProductController productController = Get.find();

  WishlistPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.find();
    controller.initUser(userEmail);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Liste de souhaits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
          );
        }

        if (controller.wishlistItems.isEmpty) {
          return _buildEmptyWishlist(); // This is the method you wanted
        }

        return _buildWishlistContent(controller);
      }),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Votre liste de souhaits est vide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à ajouter des articles à votre liste',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to stores screen
              Get.to(() => StoresScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text('Découvrir les produits'),
          ),
        ],
      ),
    );
  }

Widget _buildWishlistContent(WishlistController controller) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            couleur: '',
            quantiteStock: 0,
            averageRating: 0,
            totalReviews: 0,
            style: '',
            model3D: '', // Ajoutez ce champ si nécessaire
          );

      if (product.id == 'not_found') return const SizedBox.shrink();

      final bool has3DModel = product.model3D.isNotEmpty;

      return Dismissible(
        key: Key('${wishlistItem.productId}_${product.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red[400],
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
              backgroundColor: Colors.black87,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 8,
              duration: const Duration(seconds: 2),
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
              backgroundColor: Colors.red,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 8,
            );
          }
        },
        child: GestureDetector(
          onTap: () => product.id != 'not_found'
              ? Get.to(() => ProductDetailsScreen(product: product))
              : null,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: has3DModel
                          ? Fixed3DViewer(
                              modelUrl: product.model3D,
                              compactMode: true,
                              backgroundColor: Colors.grey[100]!,
                              enableShadow: false,
                              autoRotate: true,
                              enableZoom: false,
                              showProgress: false,
                            )
                          : product.image.isEmpty
                              ? Icon(Icons.image_rounded, color: Colors.grey)
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
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[100],
                                    child: Icon(Icons.broken_image_rounded,
                                        color: Colors.grey),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.grey,
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
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${product.prix.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 36),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Ajouter au panier',
                            style: TextStyle(fontSize: 14),
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
      );
    },
  );
}
}
