// lib/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:opti_app/core/constants/api_constants.dart';
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  @override
  Future<String> loginWithEmail(String email, String password) {
    return dataSource.loginWithEmail(email, password);
  }

  /*@override
  Future<String> loginWithGoogle(String token) {
    return dataSource.loginWithGoogle(token);
  }*/

  @override
  Future<User> getUser(String userId) async {
    final userData = await dataSource.getUser(userId);
    return UserModel.fromJson(userData);
  }

  @override
  Future<void> updateUser(String userId, User user) async {
    if (user is UserModel) {
      await dataSource.updateUser(userId, user);
    } else {
      throw Exception('User must be a UserModel instance');
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(User user) async {
    try {
      return await dataSource.signUp(user);
    } catch (e) {
      throw Exception('signup failed: $e');
    }
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
  Future<Either<Failure, void>> resetPassword(
      String email, String password) async {
    try {
      await dataSource.resetPassword(email, password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
 /*  @override
  Future<String> loginWithFacebook(String accessToken) async {
    try {
      final token = await dataSource.loginWithFacebook(accessToken);
      return token;
    } catch (e) {
      throw Exception('Repository: Facebook login failed - ${e.toString()}');
    }
  }*/
@override
Future<String> uploadImage(String filePath, String userId) async {
  try {
    return await dataSource.uploadImage(filePath, userId);
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

@override
Future<void> updateUserImage(String userId, String imageUrl) async {
  try {
    return await dataSource.updateUserImage(userId, imageUrl);
  } catch (e) {
    throw Exception('Failed to update user image: $e');
  }
}}

