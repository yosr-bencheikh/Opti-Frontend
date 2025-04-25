// Import the Optician entity

import 'package:opti_app/domain/entities/Optician.dart';

abstract class OpticianRepository {
  Future<List<Optician>> getOpticians();
  Future<void> addOptician(Optician optician);
  Future<void> updateOptician(Optician optician);
  Future<void> deleteOptician(String email);
  Future<String> loginWithEmail(String email, String password);

  Future<void> sendPasswordResetEmail(String email);
  Future<bool> verifyResetCode(String email, String code);
  Future<bool> resetPassword(String email, String code, String newPassword);
}
