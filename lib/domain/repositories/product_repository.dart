import 'dart:io';

import 'package:opti_app/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> updateProduct(String id, Product product);
  Future<void> deleteProduct(String id);
  Future<String> uploadImage(File imageFile);
  Future<Product> getProductById(String productId);
  Future<Product> createProduct(Product product);
  Future<Map<String, dynamic>> getProductRatings(String productId);
}
