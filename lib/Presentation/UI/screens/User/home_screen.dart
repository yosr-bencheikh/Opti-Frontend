import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/User/Face_detection.dart';
import 'package:opti_app/Presentation/UI/screens/User/Rotating3DModel.dart';
import 'package:opti_app/Presentation/UI/screens/User/optician_product_screen.dart';
// ignore: unused_import
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/cart_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/Presentation/widgets/productCard.dart';
import 'package:opti_app/Presentation/widgets/opticalstoreCard.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/user.dart';

class HomeScreen extends GetView<AuthController> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final RxInt _currentPage = 0.obs;
  final NavigationController navigationController = Get.find();
  final BoutiqueController opticienController = Get.find();
  final ProductController productController = Get.find();
  final WishlistController wishlistController = Get.find();

  // Add search query observable
  final RxString searchQuery = ''.obs;
  // Add flags to track search state
  final RxBool isSearching = false.obs;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentUser?.email != null) {
        wishlistController.initUser(controller.currentUser!.email);
      }

      final productController = Get.find<ProductController>();
      productController.calculatePopularProducts();

      final orderController = Get.find<OrderController>();

      // Check if orders are already loaded, if not, load them
      if (orderController.allOrders.isEmpty) {
        orderController.loadAllOrders();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = controller.currentUser;
            if (user == null) {
              return const Center(
                  child: Text('Chargement des données utilisateur...'));
            }

            return CustomScrollView(
              slivers: [
                _buildAppBar(context, user),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      // Only show search results when searching
                      if (isSearching.value && searchQuery.value.isNotEmpty)
                        _buildSearchResults()
                      else
                        Column(
                          children: [
                            _buildPromotionalBanner(context),
                            buildPopularProducts(),
                            _buildOpticalStores(),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          }),

          // Bouton animé d'analyse de visage
          ///  _FaceAnalysisButton(), // Moved to a separate widget for state management
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar(BuildContext context, User user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            child: Row(
              children: [
                Obx(() {
                  final imageUrl = controller.currentUser?.imageUrl ?? '';
                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl,
                            headers: {'Cache-Control': 'no-cache'})
                        : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${user.prenom}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.black87),
                  onPressed: () {
                    Get.to(() => CartScreen());
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.favorite_border, color: Colors.black87),
                  onPressed: () {
                    final userEmail = controller.currentUser?.email;
                    if (userEmail != null) {
                      Get.to(() => WishlistPage(userEmail: userEmail));
                    } else {
                      Get.snackbar(
                          'Erreur', 'Veuillez vous connecter d\'abord');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          searchQuery.value = value;
          isSearching.value = value.isNotEmpty;
        },
        decoration: InputDecoration(
          hintText: 'Rechercher des produits ou des magasins...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Obx(() => searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchQuery.value = '';
                    isSearching.value = false;
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                )
              : const SizedBox()),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final query = searchQuery.value.toLowerCase();

      final filteredProducts = productController.products
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              (product.marque.toLowerCase()).contains(query))
          .toList();

      final filteredOpticians = opticienController.opticiensList
          .where((optician) =>
              optician.nom.toLowerCase().contains(query) ||
              optician.email.toLowerCase().contains(query))
          .toList();

      if (filteredProducts.isEmpty && filteredOpticians.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
                'Aucun résultat trouvé. Essayez un autre terme de recherche.'),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Produits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => ProductDetailsScreen(product: product));
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 98,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              color: Colors.grey[200],
                            ),
                            child: product.image.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      product.image,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.shopping_bag, size: 40)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '\$${product.prix.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (product.marque.isNotEmpty)
                                  Text(
                                    product.marque,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (filteredOpticians.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Magasins Optiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredOpticians.length,
              itemBuilder: (context, index) {
                final optician = filteredOpticians[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.store, color: Colors.grey),
                    ),
                    title: Text(
                      optician.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(optician.email),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Get.to(() =>
                            OpticianProductsScreen(opticianId: optician.id));
                      },
                      child: const Text('Voir les Produits'),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      );
    });
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => _currentPage.value = index,
            itemCount: 3,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (index == 0) {
                    Get.toNamed('/questionnaire'); // Navigate to questionnaire
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: index == 0
                          ? [Colors.purpleAccent, Colors.deepPurpleAccent]
                          : [Colors.blueAccent, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          index == 0 ? Icons.quiz_rounded : Icons.local_offer,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          index == 0
                              ? '🎯 Participez à notre questionnaire!'
                              : '💰 Special Offer ${index + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage.value == index ? 12 : 8,
                  height: _currentPage.value == index ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage.value == index
                        ? Colors.purpleAccent
                        : Colors.grey[400],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget buildPopularProducts() {
    final productController = Get.find<ProductController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Produits Populaires',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 242,
          child: Obx(() {
            if (productController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productController.error != null) {
              return Center(child: Text('Erreur: ${productController.error}'));
            }

            final productsToDisplay =
                productController.popularProducts.isNotEmpty
                    ? productController.popularProducts
                    : productController.products.take(10).toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productsToDisplay.length,
              itemBuilder: (context, index) {
                final product = productsToDisplay[index];

                // Préparation de l'URL du modèle 3D comme dans le premier widget
                String model3DUrl = product.model3D;
                if (model3DUrl.isNotEmpty) {
                  model3DUrl =
                      GlassesManagerService.ensureAbsoluteUrl(model3DUrl);
                }

                // Création d'une copie du produit avec l'URL du modèle 3D mise à jour
                final updatedProduct = product.copyWith(model3D: model3DUrl);

                return ProductCard(
                  product: updatedProduct,
                  isHorizontalList: true,
                  wishlistController: wishlistController,
                  authController: controller,
                  customImageWidget: model3DUrl.isNotEmpty
                      ? SizedBox(
                          height: 120,
                          width: 160,
                          child: Flutter3DViewer(src: model3DUrl),
                        )
                      : null,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOpticalStores() {
    try {
      return FutureBuilder<Position>(
        future: _getUserLocation(),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (locationSnapshot.hasError || !locationSnapshot.hasData) {
            return const Center(
              child: Text('Impossible de déterminer votre position'),
            );
          }

          final userPosition = locationSnapshot.data!;

          return Obx(() {
            if (opticienController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<OpticienWithDistance>>(
              future: _getOpticiansWithDistance(
                opticienController.opticiensList,
                userPosition,
              ),
              builder: (context, distanceSnapshot) {
                if (distanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (distanceSnapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${distanceSnapshot.error}'),
                  );
                }

                final nearestOpticians = distanceSnapshot.data ?? [];

                if (nearestOpticians.isEmpty) {
                  return const Center(
                    child: Text('Aucun opticien à proximité'),
                  );
                }
                print(
                    'Nombre d\'opticiens chargés: ${opticienController.opticiensList.length}');

                // Take only the first 3 nearest boutiques
                final topThreeOpticians = nearestOpticians.take(3).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Magasins Optiques Proches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topThreeOpticians.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = topThreeOpticians[index];
                        return buildOpticianCard(
                          context,
                          item.optician,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          });
        },
      );
    } catch (e) {
      debugPrint('Error in _buildOpticalStores: $e');
      return Center(child: Text('Erreur: $e'));
    }
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<OpticienWithDistance>> _getOpticiansWithDistance(
    List<Boutique> opticians,
    Position userPosition,
  ) async {
    final List<OpticienWithDistance> results = [];

    for (var optician in opticians) {
      try {
        final locations = await locationFromAddress(
          '${optician.adresse}, ${optician.ville}',
        );

        if (locations.isNotEmpty) {
          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            locations.first.latitude,
            locations.first.longitude,
          );

          results.add(OpticienWithDistance(
            optician: optician,
            distance: distance,
          ));
        }
      } catch (e) {
        debugPrint('Error calculating distance for ${optician.nom}: $e');
      }
    }

    // Sort by distance (nearest first) and take top 5
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results.take(5).toList();
  }

  Widget _buildBottomNavBar() {
    return Obx(() => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationController.selectedIndex.value,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Magasins'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt), label: 'Commandes'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          onTap: navigationController.changePage,
        ));
  }
}

// Keep the existing showProductDialog method unchanged
Future<void> showProductDialog(BuildContext context, Product product) async {
  final RxInt quantity = 1.obs;
  final CartItemController cartController = Get.find<CartItemController>();
  final AuthController authController = Get.find<AuthController>();

  // Préparation de l'URL du modèle 3D
  String model3DUrl = product.model3D;
  if (model3DUrl.isNotEmpty) {
    model3DUrl = GlassesManagerService.ensureAbsoluteUrl(model3DUrl);
  }

  Future<void> _addToCart() async {
    final userId = authController.currentUserId.value;
    if (userId.isEmpty) {
      Get.snackbar('Erreur',
          'Veuillez vous connecter pour ajouter des articles au panier',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (product.id?.isEmpty ?? true) {
      Get.snackbar('Erreur', 'Informations produit invalides',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final totalPrice = quantity.value * product.prix;

    try {
      await cartController.createCartItem(
        userId: userId,
        productId: product.id!,
        quantity: quantity.value,
        totalPrice: totalPrice,
      );
      Navigator.of(context).pop(); // Close the dialog
      Get.snackbar('Succès', '${product.name} ajouté au panier',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Erreur',
          'Échec de l\'ajout de l\'article au panier: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(product.name),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Afficher le modèle 3D ou l'image selon la disponibilité du modèle 3D
                model3DUrl.isNotEmpty
                    ? SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Rotating3DModel(modelUrl: model3DUrl),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.image,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                Text(
                  'Prix: \$${product.prix.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity.value > 1) {
                          quantity.value--; // Corrected decrement
                        }
                      },
                    ),
                    Obx(() => Text(
                          '${quantity.value}',
                          style: const TextStyle(fontSize: 20),
                        )),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        quantity.value++; // Increase quantity
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() => Text(
                      'Total: \$${(quantity.value * product.prix).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _addToCart,
            child: const Text('Ajouter au Panier'),
          ),
        ],
      );
    },
  );
}

// Custom painter for the pulsating border
class PulsatingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;

  PulsatingBorderPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((sin(progress * 2 * 3.14159) + 1) / 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant PulsatingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FaceAnalysisButton extends StatefulWidget {
  @override
  __FaceAnalysisButtonState createState() => __FaceAnalysisButtonState();
}

class __FaceAnalysisButtonState extends State<_FaceAnalysisButton> {
  bool _isButtonVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isButtonVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 400, // Increased from 80 to 100 to add spacing
      right: 20,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(seconds: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 220,
              height: 102,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isButtonVisible = false; // Hide the button
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),

                  // Button content
                  InkWell(
                    onTap: () {
                      print("Button tapped!"); // Debugging line
                      // Navigation to FaceDetectionScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FaceDetectionScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Animated icon
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 2 * 3.14159),
                            duration: Duration(seconds: 3),
                            curve: Curves.elasticOut,
                            builder: (context, double value, child) {
                              return Transform.rotate(
                                angle: sin(value) * 0.1,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.face_retouching_natural,
                                    color: Colors.blue.shade700,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Analysez votre visage !",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Trouvez les lunettes parfaites pour vous",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pulsating animation
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return RepaintBoundary(
                        child: CustomPaint(
                          size: Size(220, 100),
                          painter: PulsatingBorderPainter(
                            progress: value,
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OpticienWithDistance {
  final Boutique optician;
  final double distance;

  OpticienWithDistance({
    required this.optician,
    required this.distance,
  });
}
