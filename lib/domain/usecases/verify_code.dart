import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class VerifyCode {
  final AuthRepository repository;

  VerifyCode(this.repository);

  Future<void> call(String email, String code) async {
    return await repository.verifyCode(email, code);
  }
}
