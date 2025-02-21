import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';

class AddProductUseCase {
  final ProductRepository repository;

  AddProductUseCase(this.repository);

  Future<Product> execute(Product product) async {
    return await repository.addProduct(product);
  }
}

class UploadImageUseCase {
  final ProductRepository repository;

  UploadImageUseCase(this.repository);

  Future<String> execute(String imagePath) async {
    return await repository.uploadImage(imagePath);
  }
}