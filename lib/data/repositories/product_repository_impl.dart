import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'dart:io';
import 'package:opti_app/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDatasource dataSource;

  ProductRepositoryImpl({required this.dataSource});
  Future<List<Product>> getProducts() async {
    return await dataSource.getProducts();
  }

  Future<Product> createProduct(Product product) async {
    return await dataSource.createProduct(product);
  }

  Future<Product> updateProduct(String id, Product product) async {
    return await dataSource.updateProduct(id, product);
  }

  Future<void> deleteProduct(String id) async {
    return await dataSource.deleteProduct(id);
  }

  Future<String> uploadImage(File imageFile) async {
    return await dataSource.uploadImage(imageFile);
  }

  Future<Product> getProductById(String productId) async {
    return await dataSource.getProductById(productId);
  }

  Future<List<Opticien>> getOpticiens() async {
    return await dataSource.getOpticiens();
  }
}
