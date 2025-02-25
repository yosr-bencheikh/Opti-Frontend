import 'dart:io';
import 'package:get/get.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';

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

  Future<void> loadProducts() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final products = await _repository.getProducts();
      _products.assignAll(products); // Use assignAll for RxList
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
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