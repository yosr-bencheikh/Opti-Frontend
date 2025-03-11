
import 'package:opti_app/domain/entities/user.dart';


abstract class AuthRepository {
  Future<bool> verifyToken(String token);
  Future<String> loginWithEmail(String email, String password);
  Future<Map<String, dynamic>> signUp(User user);
  Future<User> getUser(String userId);
  Future<void> updateUser(String userId, User user);
  Future<void> sendCodeToEmail(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> resetPassword(String email, String password);
  Future<String> uploadImage(String filePath, String userId);
  Future<void> updateUserImage(String userId, String imageUrl);
  Future<Map<String, dynamic>> getUserByEmail(String email);
  Future<String> refreshToken(String refreshToken);
  Future<void> deleteUserImage(String email);
  Future<Map<String, dynamic>> getUserById(String userId);
}
