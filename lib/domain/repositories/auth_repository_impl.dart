import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<String> loginWithEmail(String email, String password) {
    return dataSource.loginWithEmail(email, password);
  }

  @override
  Future<String> loginWithGoogle(String token) {
    return dataSource.loginWithGoogle(token);
  }
}