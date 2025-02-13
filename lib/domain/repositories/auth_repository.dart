import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<String> loginWithEmail(String email, String password);
 // Future<String> loginWithGoogle(String token);
 // Future<String> loginWithFacebook(String accessToken);
  Future<Map<String, dynamic>> signUp(User user);
  Future<Either<Failure, void>> sendCodeToEmail(String email);
  Future<Either<Failure, void>> verifyCode(String email, String code);
  Future<Either<Failure, void>> resetPassword(String email, String password);
  updateUser(String userId, User user);
  getUser(String userId);
 Future<String> uploadImage(String filePath, String userId);
   Future<void> updateUserImage(String userId, String imageUrl); 
}
