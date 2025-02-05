import 'package:opti_app/domain/repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  Future<String> execute(String email, String password) {
    return repository.loginWithEmail(email, password);
  }
}