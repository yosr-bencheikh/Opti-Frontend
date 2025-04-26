import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart';
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
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Colors.black87, size: 26),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de votre liste...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Votre liste de souhaits est vide',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez des articles à votre liste pour les retrouver facilement plus tard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Découvrir les produits',
                  style: TextStyle(
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
                            ? FutureBuilder<bool>(
                                future:
                                    _checkModelAvailability(normalizedModelUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ));
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data == true) {
                                    return Stack(
                                      children: [
                                        Flutter3DViewer(
                                          src: normalizedModelUrl,
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
                                                child:
                                                    CircularProgressIndicator(
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
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                              child: Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(Icons.image_rounded,
                                                color: Colors.grey));
                                  }
                                },
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
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
