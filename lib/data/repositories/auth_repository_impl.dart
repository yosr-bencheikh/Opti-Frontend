import 'package:dartz/dartz.dart';
import 'package:opti_app/core/constants/api_constants.dart';
import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<bool> verifyToken(String token) async {
    try {
      return await dataSource.verifyToken(token);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<String> loginWithEmail(String email, String password) async {
    try {
      return await dataSource.loginWithEmail(email, password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(User user) async {
    try {
      return await dataSource.signUp(user);
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  @override
  Future<User> getUser(String userId) async {
    try {
      final userData = await dataSource.getUser(userId);
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> updateUser(String userId, User user) async {
    try {
      await dataSource.updateUser(userId, user);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> sendCodeToEmail(String email) async {
    try {
      await dataSource.sendCodeToEmail(email);
    } catch (e) {
      throw Exception('Failed to send code: $e');
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    try {
      await dataSource.verifyCode(email, code);
    } catch (e) {
      throw Exception('Failed to verify code: $e');
    }
  }

  @override
  Future<void> resetPassword(String email, String password) async {
    try {
      await dataSource.resetPassword(email, password);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

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
      await dataSource.updateUserImage(userId, imageUrl);
    } catch (e) {
      throw Exception('Failed to update user image: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      return await dataSource.getUserByEmail(email);
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      return await dataSource.refreshToken(refreshToken);
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  @override
  Future<void> deleteUserImage(String email) async {
    try {
      return await dataSource.deleteUserImage(email);
    } catch (e) {
      throw Exception('Error deleting the image: $e');
    }
  }
}
