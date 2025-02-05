import 'dart:io';

import '../entities/token.dart';
import '../entities/user.dart';

abstract class AuthenticationRepository {
  Future<void> createAccount({
    required String role,
    required String? address,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String phone,
    required String image,
    required String? oauth,
    required String? birthDate,
    required String? gender,
  });

  Future<void> login({required String email, required String password});

  Future<void> autologin();

  Future<void> updateProfil({
    required String address,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String id,
    required String birthDate,
    required String gender,
  });

  Future<void> logout();

  Future<void> clearUserImage(String userId);

  Future<void> facebookLogin();

  Future<void> googleLogin();

  Future<void> resetPassword({required String email, required String password});

  Future<void> forgetPassword(String email);

  Future<void> verifyOTP({required String email, required int otp});

  Future<void> getUser(String id);

  Future<void> updatePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  });

  Future<void> updateUserImage({required String userId, required File file});
}
