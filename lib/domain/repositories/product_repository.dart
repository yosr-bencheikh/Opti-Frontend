import 'package:opti_app/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<String> uploadImage(String imagePath);
}