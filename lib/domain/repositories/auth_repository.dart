import 'package:opti_app/domain/entities/user.dart';

abstract class AuthRepository {
  Future<String> loginWithEmail(String email, String password);
  Future<String> loginWithGoogle(String token);
  Future<void> signUp(User user);


}