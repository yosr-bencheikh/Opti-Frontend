import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';

class GetUser {
  final AuthRepository repository;

  GetUser(this.repository);

  Future<User> call(String userId) async {
    return await repository.getUser(userId);
  }
}
