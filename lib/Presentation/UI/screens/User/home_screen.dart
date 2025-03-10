import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/optician_product_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/cart_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

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
    });

    return Scaffold(
      body: Obx(() {
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
                        _buildPromotionalBanner(),
                        _buildPopularProducts(),
                        _buildOpticalStores(),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      }),
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
              (product.marque?.toLowerCase() ?? '').contains(query))
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
                                if (product.marque != null &&
                                    product.marque!.isNotEmpty)
                                  Text(
                                    product.marque!,
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

  Widget _buildPromotionalBanner() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => _currentPage.value = index,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[100 * (index + 1)],
                ),
                child: Center(
                  child: Text(
                    'Promotion ${index + 1}',
                    style: const TextStyle(fontSize: 24.0),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage.value == index
                        ? Colors.blue
                        : Colors.grey[300],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPopularProducts() {
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
          height: 220,
          child: Obx(() {
            if (productController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productController.error != null) {
              return Center(child: Text('Erreur: ${productController.error}'));
            }

            if (productController.products.isEmpty) {
              return const Center(child: Text('Aucun produit disponible'));
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productController.products.length,
              itemBuilder: (context, index) {
                final product = productController.products[index];

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
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-5%',
                                      style: TextStyle(
                                        color: Colors.pink[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  Text(
                                    ' ${product.averageRating.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    ' (${product.totalReviews})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.black87),
                                    onPressed: () {
                                      if (product.id == null ||
                                          product.id!.isEmpty) {
                                        Get.snackbar('Erreur',
                                            'Données produit invalides');
                                        return;
                                      }
                                      showProductDialog(context, product);
                                    },
                                  ),
                                  Obx(() {
                                    final isInWishlist = wishlistController
                                        .isProductInWishlist(product.id!);
                                    return IconButton(
                                      icon: Icon(
                                        isInWishlist
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isInWishlist
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                      onPressed: () async {
                                        final userEmail =
                                            controller.currentUser?.email;
                                        if (userEmail == null) {
                                          Get.snackbar('Erreur',
                                              'Veuillez vous connecter d\'abord');
                                          return;
                                        }

                                        try {
                                          if (isInWishlist) {
                                            await wishlistController
                                                .removeFromWishlist(
                                                    product.id!);
                                          } else {
                                            final wishlistItem = WishlistItem(
                                              userId: userEmail,
                                              productId: product.id!,
                                            );
                                            await wishlistController
                                                .addToWishlist(wishlistItem);
                                          }
                                        } catch (e) {
                                          Get.snackbar(
                                            'Erreur',
                                            'Échec de la mise à jour de la liste de souhaits: ${e.toString()}',
                                            backgroundColor: Colors.red[100],
                                            colorText: Colors.red[900],
                                          );
                                        }
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOpticalStores() {
    return Obx(() {
      if (opticienController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final opticians = opticienController.opticiensList;

      if (opticians.isEmpty) {
        return const Center(child: Text('Aucun opticien trouvé.'));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            itemCount: opticians.length,
            itemBuilder: (context, index) {
              final optician = opticians[index];
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
      );
    });
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.image,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
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
                          quantity.value =
                              quantity.value--; // Decrease quantity
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
