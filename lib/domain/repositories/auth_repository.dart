abstract class AuthRepository {
  Future<String> loginWithEmail(String email, String password);
  Future<String> loginWithGoogle(String token);
}