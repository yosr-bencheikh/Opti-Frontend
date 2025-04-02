import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends GetxController {
  final ProductRepositoryImpl _repository;
  final ProductDatasource _dataSource;

  // Convert to observable variables using .obs
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Boutique> _opticiens = <Boutique>[].obs;
  final RxBool _isLoading = false.obs;
  final Rxn<String> _error = Rxn<String>();
  final RxList<Product> _popularProducts = <Product>[].obs;
  List<Product> get popularProducts => _popularProducts;

  ProductController(this._repository, this._dataSource);

  // Getters for the observable variables
  List<Product> get products => _products;
  List<Boutique> get opticiens => _opticiens;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  final RxMap<String, List<Product>> _productsByOptician =
      <String, List<Product>>{}.obs;
  final RxList<Product> _allProducts = <Product>[].obs;
  Future<void> loadOpticiens() async {
    try {
      // This will need to be implemented in your repository
      // For now, I'm assuming there's a getOpticiens method in the repository
      final opticiens = await _repository.getOpticiens();
      _opticiens.assignAll(opticiens);
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> loadProducts() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final products = await _repository.getProducts();
      _allProducts.assignAll(products); // Store all products in _allProducts
      _products.assignAll(products); // Also update current display list
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadOpticiens();
  }

  Future<void> loadAllProductsForOptician() async {
    try {
      _isLoading.value = true; // Changed from isLoading(true)
      _error.value = ''; // Changed from error('')

      // 1. Get logged-in optician
      final opticianController = Get.find<OpticianController>();
      if (!opticianController.isLoggedIn.value) {
        throw Exception('User not logged in');
      }

      // 2. Get all boutiques for this optician
      final boutiqueController = Get.find<BoutiqueController>();
      await boutiqueController
          .getboutiqueByOpticianId(opticianController.currentUserId.value);
      final boutiqueIds =
          boutiqueController.opticiensList.map((b) => b.id).toList();

      // 3. Load products for all boutiques
      if (boutiqueIds.isNotEmpty) {
        final allProducts = <Product>[];
        for (final boutiqueId in boutiqueIds) {
          final products =
              await _repository.getProductsByBoutiqueId(boutiqueId);
          allProducts.addAll(products);
        }
        _products.assignAll(allProducts);
        _allProducts.assignAll(allProducts);
      } else {
        _products.clear();
        _allProducts.clear();
      }
    } catch (e) {
      _error.value = 'Error: ${e.toString()}';
    } finally {
      _isLoading.value = false; // Changed from isLoading(false)
    }
  }

  Future<void> loadProductsForCurrentOptician() async {
    try {
      _isLoading.value = true;

      // 1. Obtenir l'opticien connecté
      final opticianController = Get.find<OpticianController>();
      if (!opticianController.isLoggedIn.value) {
        throw Exception('User not logged in');
      }

      // 2. Obtenir les boutiques de cet opticien
      final boutiqueController = Get.find<BoutiqueController>();
      await boutiqueController
          .getboutiqueByOpticianId(opticianController.currentUserId.value);
      final boutiqueIds =
          boutiqueController.opticiensList.map((b) => b.id).toList();

      // 3. Charger les produits de ces boutiques
      if (boutiqueIds.isNotEmpty) {
        final products = await _repository.getProductsByBoutiques(boutiqueIds);
        _products.assignAll(products);
      } else {
        _products.clear();
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> calculatePopularProducts() async {
    _isLoading.value = true;
    try {
      final orderController = Get.find<OrderController>();
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      final Map<String, int> productPopularity = {};
      final validStatuses = ['Completée', 'Completed', 'Complete'];

      for (final order in orderController.allOrders) {
        final isValidStatus = validStatuses.any(
            (status) => order.status?.toLowerCase() == status.toLowerCase());

        if (order.createdAt.month == currentMonth &&
            order.createdAt.year == currentYear &&
            (isValidStatus ?? false)) {
          for (final item in order.items) {
            if (item.productId != null) {
              productPopularity.update(
                item.productId!,
                (value) => value + (item.quantity ?? 0),
                ifAbsent: () => item.quantity ?? 0,
              );
            }
          }
        }
      }

      final popularProducts = productPopularity.entries
          .where((entry) => _allProducts.any((p) => p.id == entry.key))
          .map((entry) {
        final product = _allProducts.firstWhere((p) => p.id == entry.key);
        return _PopularProduct(product, entry.value);
      }).toList()
        ..sort((a, b) => b.popularity.compareTo(a.popularity));

      _popularProducts
          .assignAll(popularProducts.map((e) => e.product).take(10).toList());
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  // In the existing ProductController class, update the method:
  void updateProductRating(
      String productId, double newRating, int newTotalReviews) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].copyWith(
        averageRating: newRating,
        totalReviews: newTotalReviews,
      );
      _products[index] = updatedProduct;
      update();
    }
  }

  Future<void> fetchProductRatingAndReviews(String productId) async {
    try {
      final response = await _repository.getProductRatings(productId);

      // Update in main products list
      final productIndex = _products.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        final updatedProduct = _products[productIndex].copyWith(
          averageRating: response['averageRating'] ?? 0.0,
          totalReviews: response['totalReviews'] ?? 0,
        );
        _products[productIndex] = updatedProduct;
        _products.refresh(); // Trigger UI update
      }

      // Update in all products list
      final allProductIndex = _allProducts.indexWhere((p) => p.id == productId);
      if (allProductIndex != -1) {
        final updatedProduct = _allProducts[allProductIndex].copyWith(
          averageRating: response['averageRating'] ?? 0.0,
          totalReviews: response['totalReviews'] ?? 0,
        );
        _allProducts[allProductIndex] = updatedProduct;
        _allProducts.refresh();
      }
    } catch (e) {
      print('Error updating ratings: $e');
    }
  }

  String? getOpticienNom(String opticienId) {
    final opticien = _opticiens.firstWhereOrNull((o) => o.id == opticienId);
    return opticien?.nom;
  }

  Future<void> loadProductsByOptician(String boutiqueId) async {
    // Set loading state
    _isLoading.value = true;

    try {
      // First, make sure we have all products loaded
      if (_allProducts.isEmpty) {
        final products = await _repository.getProducts();
        _allProducts.assignAll(products);
      }

      // Filter the products by optician ID
      final opticianProducts =
          _allProducts.where((p) => p.boutiqueId == boutiqueId).toList();

      // After all processing is done, update the UI state
      _products.assignAll(opticianProducts);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  void showAllProducts() {
    _isLoading.value = true;
    try {
      // Make sure to use the complete list of products
      if (_allProducts.isNotEmpty) {
        _products.assignAll(_allProducts);
      } else {
        // If _allProducts is empty, reload all products from repository
        loadProducts();
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void resetProductList() {
    _products.assignAll(_allProducts);
  }

  Future<bool> addProduct(Product product) async {
    try {
      _isLoading.value = true;
      final newProduct = await _repository.createProduct(product);

      // Ajouter le nouveau produit à la liste en début de liste pour qu'il soit visible immédiatement
      _products.insert(0, newProduct);

      // Forcer la mise à jour de l'interface
      _products.refresh();

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateProduct(String id, Product product) async {
    try {
      _isLoading.value = true;
      final updatedProduct = await _repository.updateProduct(id, product);

      // Mettre à jour dans la liste des produits
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        // Forcer la mise à jour de l'interface
        _products.refresh();
      }

      // Mettre à jour également dans la liste complète des produits
      final allIndex = _allProducts.indexWhere((p) => p.id == id);
      if (allIndex != -1) {
        _allProducts[allIndex] = updatedProduct;
        _allProducts.refresh();
      }

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String productId) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // First, upload the image
      final imageUrl =
          await _dataSource.uploadImageWeb(imageBytes, fileName, productId);

      // Don't try to create a product here - just return the image URL
      // The product should be created later with all required fields
      _isLoading.value = false;
      Get.snackbar('Succès', 'Image téléchargée avec succès',
          snackPosition: SnackPosition.BOTTOM);
      return imageUrl;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
          'Erreur', 'Échec du téléchargement de l\'image: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM);
      throw Exception('Échec du téléchargement de l\'image: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      _isLoading.value = true;

      final imageUrl = await _repository.uploadImage(imageFile);

      _isLoading.value = false;
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      _error.value = e.toString();
      _isLoading.value = false;
      return null;
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      return await _repository.getProductById(productId);
    } catch (e) {
      _error.value = e.toString();
      throw e;
    }
  }

  Future<Map<String, dynamic>> getRecommendations(String faceShape) async {
    try {
      final data = await _dataSource.fetchRecommendations(faceShape);
      return {
        'stylesRecommendées':
            List<String>.from(data['stylesRecommendées'] ?? []),
        'products': data['products'] ?? [],
        'error': null
      };
    } catch (e) {
      print('Error in controller: $e');
      // Fall back to hardcoded recommendations
      return {
        'stylesRecommendées':
            _dataSource.getHardcodedStyleRecommendations(faceShape),
        'products': [],
        'error': e.toString()
      };
    }
  }
}

class _PopularProduct {
  final Product product;
  final int popularity;

  _PopularProduct(this.product, this.popularity);
}
