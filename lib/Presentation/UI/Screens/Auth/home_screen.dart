import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/cart_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/optician_product_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/product_details_screen.dart';

import 'package:opti_app/Presentation/UI/screens/auth/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/opticien_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final RxInt _currentPage = 0.obs;
  
  // Controllers
  late NavigationController navigationController;
  late OpticienController opticienController;
  late ProductController productController;
  late WishlistController wishlistController;
  late AuthController authController;
  
  final RxMap<String, bool> _favorites = <String, bool>{}.obs;
  
  // Track which products should display 3D models
  final RxMap<String, bool> _show3DModel = <String, bool>{}.obs;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    navigationController = Get.find<NavigationController>();
    opticienController = Get.find<OpticienController>();
    productController = Get.find<ProductController>();
    wishlistController = Get.find<WishlistController>();
    authController = Get.find<AuthController>();
    
    // Use a post-frame callback to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset and load all products
      productController.showAllProducts();
      
      // Initialize user for wishlist if logged in
      if (authController.currentUser?.email != null) {
        wishlistController.initUser(authController.currentUser!.email);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (authController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = authController.currentUser;
        if (user == null) {
          return const Center(child: Text('Loading user data...'));
        }

        return CustomScrollView(
          slivers: [
            _buildAppBar(context, user),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildPromotionalBanner(),
                  _buildPopularProducts(),
                  _buildOpticalStores(),
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
                  final imageUrl = authController.currentUser?.imageUrl ?? '';
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
                        'Hello, ${user.prenom}',
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
                    final userEmail = authController.currentUser?.email;
                    if (userEmail != null) {
                      Get.to(() => WishlistPage(userEmail: userEmail));
                    } else {
                      Get.snackbar('Error', 'Please log in first');
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
        decoration: InputDecoration(
          hintText: 'Search products or stores...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
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
            if (index == 1) {
              // Display 3D model for the second promotional banner
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[100 * (index + 1)],
                ),
                child: Center(
                  child: ModelViewer(
                    src: 'assets/models/scene.gltf', // Path to your 3D model
                    alt: 'A 3D model of glasses',
                    ar: true,
                    autoRotate: true,
                    cameraControls: true,
                  ),
                ),
              );
            } else {
              // Regular promotional banners
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
              
                child: Center(
                  child: Text(
                    'Promotion ${index + 1}',
                    style: const TextStyle(fontSize: 24.0),
                  ),
                ),
              );
            }
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
            'Popular Products',
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
              return Center(child: Text('Error: ${productController.error}'));
            }

            if (productController.products.isEmpty) {
              return const Center(child: Text('No products available'));
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productController.products.length,
              itemBuilder: (context, index) {
                final product = productController.products[index];
                // Check if product is glasses (you might want to add a category field to your product model)
                final bool isGlasses = product.name.toLowerCase().contains('glasses') || 
                                      product.name.toLowerCase().contains('lunettes') ||
                                      (product.category?.toLowerCase() == 'glasses');
                
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
                        // Product image or 3D model
                        Stack(
                          children: [
                            Container(
                              height: 98,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                color: Colors.grey[200],
                              ),
                              // Standard image display if not showing 3D model
                              child: Obx(() => _show3DModel[product.id] != true
                                ? (product.image != null &&
                                        product.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12)),
                                        child: Image.network(
                                          product.image!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 98,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.shopping_bag, size: 40)))
                                : isGlasses 
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 98,
                                        child: ModelViewer(
                                          src: 'assets/models/scene.gltf',
                                          autoRotate: true,
                                          cameraControls: false,
                                          ar: false,
                                          disableZoom: true,
                                          backgroundColor: Colors.grey[200]!.withOpacity(0.5),
                                        ),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Image.network(
                                        product.image!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 98,
                                      ),
                                    ),
                              ),
                            ),
                            // 3D button overlay (only for glasses products)
                            if (isGlasses)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                // Before trying to use product.id as a key, check if it's null
onTap: () {
  if (product.id != null) {
    final currentValue = _show3DModel[product.id!] ?? false;
    _show3DModel[product.id!] = !currentValue;
  }
},
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Obx(() => Icon(
                                      _show3DModel[product.id] == true
                                          ? Icons.view_in_ar_outlined
                                          : Icons.view_in_ar,
                                      color: Colors.white,
                                      size: 18,
                                    )),
                                  ),
                                ),
                              ),
                          ],
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
                                    ' 4.8',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    ' (25)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              // Shopping cart and favorite buttons
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
                                        Get.snackbar(
                                            'Error', 'Invalid product data');
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
                                            ? const Color.fromARGB(255, 112, 66, 62)
                                            : Colors.black87,
                                      ),
                                      onPressed: () async {
                                        final userEmail =
                                            authController.currentUser?.email;
                                        if (userEmail == null) {
                                          Get.snackbar(
                                              'Error', 'Please log in first');
                                          return;
                                        }

                                        try {
                                          if (isInWishlist) {
                                            final wishlistItem =
                                                wishlistController
                                                    .getWishlistItemByProductId(
                                                        product.id!);
                                            if (wishlistItem != null) {
                                              await wishlistController
                                                  .removeFromWishlist(
                                                      wishlistItem.id);
                                            }
                                          } else {
                                            final wishlistItem = WishlistItem(
                                              id: '', // Générer un ID unique si nécessaire
                                              product: product,
                                              userId: userEmail,
                                              productId: product.id!,
                                            );
                                            await wishlistController
                                                .addToWishlist(wishlistItem);
                                          }
                                        } catch (e) {
                                          Get.snackbar(
                                            'Error',
                                            'Failed to update wishlist',
                                            backgroundColor: Colors.red[100],
                                            colorText: Colors.red[900],
                                          );
                                        }
                                      },
                                    );
                                  })
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
        return const Center(child: Text('No opticians found.'));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Optical Stores',
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
                  subtitle: Text(
                    optician.email,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Navigate to the OpticianProductsScreen and pass the optician ID
                      Get.to(() =>
                          OpticianProductsScreen(opticianId: optician.id));
                    },
                    child: const Text('View Products'),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stores'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: navigationController.changePage,
        ));
  }
}

// Product dialog implementation remains unchanged
Future<void> showProductDialog(BuildContext context, Product product) async {
  // Reactive quantity variable
  final RxInt quantity = 1.obs;
  final CartItemController cartController = Get.find<CartItemController>();
  final AuthController authController = Get.find<AuthController>();

  // Function to add the product to the cart
  Future<void> _addToCart() async {
    final userId = authController.currentUserId.value;
    if (userId.isEmpty) {
      Get.snackbar('Error', 'Please log in to add items to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (product.id?.isEmpty ?? true) {
      Get.snackbar('Error', 'Invalid product information',
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
      Get.snackbar('Success', '${product.name} added to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add item to cart: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Show the dialog
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
                // Check if product is glasses to show 3D model in dialog
                product.name.toLowerCase().contains('glasses') || 
                product.name.toLowerCase().contains('lunettes') ||
                (product.category?.toLowerCase() == 'glasses')
                ? SizedBox(
                    height: 150,
                    child: ModelViewer(
                      src: 'assets/models/scene.gltf',
                      ar: false,
                      autoRotate: true,
                      cameraControls: true,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.image ?? '',
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
                  'Price: \$${product.prix.toStringAsFixed(2)}',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addToCart,
            child: const Text('Add to Cart'),
          ),
        ],
      );
    },
  );
}

// 3D Glasses Page - Separate page for full screen view


class Glasses3DPage extends StatelessWidget {
  final String modelPath;

  const Glasses3DPage({Key? key, this.modelPath = 'assets/models/scene.gltf'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("3D Glasses View")),
      body: Center(
        child: ModelViewer(
          src: modelPath,
          ar: true,
          autoRotate: true,
          cameraControls: true,
        ),
      ),
    );
  }
}