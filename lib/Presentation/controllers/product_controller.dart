import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends GetxController {
  final ProductRepositoryImpl _repository;
  final ProductDatasource _dataSource;

  // Convert to observable variables using .obs
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Opticien> _opticiens = <Opticien>[].obs;
  final RxBool _isLoading = false.obs;
  final Rxn<String> _error = Rxn<String>();

  ProductController(this._repository, this._dataSource);

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
}
