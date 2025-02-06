import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class GetUser {
  final UserRepository repository;

  GetUser(this.repository);

  Future<User> call(String userId) async {
    return await repository.getUser(userId);
  }
}