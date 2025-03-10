import 'dart:io';
import 'package:get/get.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends GetxController {
  final ProductRepositoryImpl _repository;

  // Convert to observable variables using .obs
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Opticien> _opticiens = <Opticien>[].obs;
  final RxBool _isLoading = false.obs;
  final Rxn<String> _error = Rxn<String>();

  ProductController(this._repository);

  // Getters for the observable variables
  List<Product> get products => _products;
  List<Opticien> get opticiens => _opticiens;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  final RxMap<String, List<Product>> _productsByOptician =
      <String, List<Product>>{}.obs;
  final RxList<Product> _allProducts = <Product>[].obs;
  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadOpticiens();
  }

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

  Future<void> loadProductsByOptician(String opticianId) async {
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
          _allProducts.where((p) => p.opticienId == opticianId).toList();

      // After all processing is done, update the UI state
      _products.assignAll(opticianProducts);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadProducts() async {
    try {
      final products = await _repository.getProducts();
      _products.assignAll(products);
      print('Products fetched: ${_products.length}'); // Debugging line
    } catch (e) {
      print('Error fetching products: $e'); // Debugging line
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

      // Ajouter le nouveau produit à la liste
      _products.add(newProduct);

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

  Future<void> updateProduct(String id, Product product) async {
    try {
      final updatedProduct = await _repository.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
    } catch (e) {
      _error.value = e.toString();
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
}
