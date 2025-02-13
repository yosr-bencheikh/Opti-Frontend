import 'package:opti_app/domain/repositories/auth_repository.dart';

class UploadImageUseCase {
  final AuthRepository repository;

  UploadImageUseCase(this.repository);

  Future<String> call(String filePath, String userId) async {
    return await repository.uploadImage(filePath , userId);
  }
}
