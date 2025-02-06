import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

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

  @override
  Future<void> signUp(User user) async {
    await dataSource.signUp(user);
  }

   @override
  Future<Either<Failure, void>> sendCodeToEmail(String email) async {
    try {
      await dataSource.sendCodeToEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyCode(String email, String code) async {
    try {
      await dataSource.verifyCode(email, code);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String password) async {
    try {
      await dataSource.resetPassword(email, password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

}
