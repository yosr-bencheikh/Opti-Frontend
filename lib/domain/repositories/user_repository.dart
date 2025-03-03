import 'package:opti_app/domain/entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserByEmail(String email);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String email);
    Future<String> uploadImage(String filePath, String userId);

}