import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<User>> getUsers() async {
    return await dataSource.getUsers();
  }

  @override
  Future<User> getUserByEmail(String email) async {
    return await dataSource.getUserByEmail(email);
  }

  @override
  Future<void> updateUser(User user) async {
    await dataSource.updateUser(user);
  }

  @override
  Future<void> deleteUser(String email) async {
    await dataSource.deleteUser(email);
  }
    @override
  Future<String> uploadImage(String filePath, String userId) async {
    try {
      return await dataSource.uploadImage(filePath, userId);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}