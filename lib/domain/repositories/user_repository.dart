import 'package:opti_app/data/models/user_model.dart';

abstract class UserRepository {
  Future<List<UserModel>> getUsers();
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
}