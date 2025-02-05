import 'package:opti_app/domain/repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository repository;

  LoginWithGoogleUseCase(this.repository);

  Future<String> execute(String token) {
    return repository.loginWithGoogle(token);
  }
}