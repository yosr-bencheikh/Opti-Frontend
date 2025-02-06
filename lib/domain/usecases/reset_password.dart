import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<Either<Failure, void>> call(String email, String password) async {
    return await repository.resetPassword(email, password);
  }
}