import 'dart:io';
import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends GetxController {
  final ProductDatasource _datasource;

  // Convert to observable variables using .obs
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Opticien> _opticiens = <Opticien>[].obs;
  final RxBool _isLoading = false.obs;
  final Rxn<String> _error = Rxn<String>();

  ProductController(this._datasource);

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
      final opticiens = await _datasource.getOpticiens();
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
      final products = await _datasource.getProducts();
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
      final newProduct = await _datasource.createProduct(product);
      
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
      final updatedProduct = await _datasource.updateProduct(id, product);
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
      await _datasource.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      _isLoading.value = true;

      final imageUrl = await _datasource.uploadImage(imageFile);

      _isLoading.value = false;
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      _error.value = e.toString();
      _isLoading.value = false;
      return null;
    }
  }
}