// lib/domain/usecases/send_code_to_email.dart
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class SendCodeToEmail {
  final AuthRepository repository;

  SendCodeToEmail(this.repository);

  Future<void> call(String email) async {
    return await repository.sendCodeToEmail(email);
  }
}
