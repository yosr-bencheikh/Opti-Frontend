import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';

class UpdateUser {
  final AuthRepository repository;

  UpdateUser(this.repository);

  Future<void> call(String userId, User user) async {
    return await repository.updateUser(userId, user);
  }
}
