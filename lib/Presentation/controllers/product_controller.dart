import 'dart:io';
import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductController extends GetxController {
  final ProductDatasource _datasource;
  var products = <Product>[].obs;
  var isLoading = false.obs;
  var error = RxnString();

  ProductController(this._datasource);

  Future<void> loadProducts() async {
    isLoading.value = true;
    error.value = null;

    try {
      final productList = await _datasource.getProducts();
      products.assignAll(productList);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _datasource.createProduct(product);
      products.add(newProduct);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      final updatedProduct = await _datasource.updateProduct(id, product);
      final index = products.indexWhere((p) => p.id == id);
      if (index != -1) {
        products[index] = updatedProduct;
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _datasource.deleteProduct(id);
      products.removeWhere((p) => p.id == id);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      isLoading.value = true;
      final imageUrl = await _datasource.uploadImage(imageFile);
      return imageUrl;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
