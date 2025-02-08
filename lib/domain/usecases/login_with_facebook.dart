import 'package:opti_app/domain/repositories/auth_repository.dart';

class LoginWithFacebookUseCase {
  final AuthRepository repository;

  LoginWithFacebookUseCase(this.repository);

  Future<String> execute(String accessToken) async {
    try {
      return await repository.loginWithFacebook(accessToken);
    } catch (e) {
      throw Exception('Facebook login failed: ${e.toString()}');
    }
  }
}