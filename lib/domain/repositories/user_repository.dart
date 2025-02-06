import 'package:opti_app/domain/entities/user.dart';

abstract class UserRepository {
  Future<User> getUser(String userId);
  Future<void> updateUser(String userId, User user);
}