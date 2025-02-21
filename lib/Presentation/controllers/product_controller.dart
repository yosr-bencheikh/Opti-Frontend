import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends ChangeNotifier {
  final ProductDatasource _datasource;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductController(this._datasource);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _datasource.getProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _datasource.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      final updatedProduct = await _datasource.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _datasource.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> uploadImage(File imageFile) async {
try {
    _isLoading = true;
    notifyListeners();

    final imageUrl = await _datasource.uploadImage(imageFile);

    _isLoading = false;
    notifyListeners();

    return imageUrl;
  } catch (e) {
    print("Error uploading image: $e");
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return null;
  }
}
}