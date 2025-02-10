import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/Presentation/utils/jwt_utils.dart';

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final SharedPreferences prefs;

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUserId = ''.obs;
  var currentUser = Rx<User?>(null);
  var authToken = ''.obs;

  AuthController({
    required this.authRepository,
    required this.prefs,
  });

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  void checkLoginStatus() {
    final String? userId = prefs.getString('userId');
    final String? token = prefs.getString('token');

    if (userId != null && token != null) {
      currentUserId.value = userId;
      authToken.value = token;
      isLoggedIn.value = true;
      loadUserData(userId);
    }
  }

 Future<void> loadUserData(String userId) async {
  try {
    print('Loading user data for ID: $userId');
    final userData = await authRepository.getUser(userId);
    
    if (userData == null) {
      print('Null response from server');
      throw Exception('Server returned null');
    }

    print('Received user data: ${userData.toString()}');
    currentUser.value = User.fromJson(userData);
    
  } catch (e) {
    print('loadUserData ERROR: ${e.toString()}');
    Get.snackbar(
      'Error',
      'Failed to load profile: ${e.toString()}',
      duration: Duration(seconds: 5),
    );
  }
}
  Future<void> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password');
      return;
    }

    isLoading.value = true;
    try {
      final response = await authRepository.loginWithEmail(email, password);

      if (response == null || response.isEmpty) {
        throw Exception('Invalid response from server');
      }

      // Store the token
      authToken.value = response;
      await prefs.setString('token', response);

      // Extract user ID from token
      try {
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(response);
        final String? userId = decodedToken['userId']?.toString() ??
            decodedToken['sub']?.toString() ??
            decodedToken['id']?.toString();

        if (userId == null || userId.isEmpty) {
          throw Exception('Unable to extract user ID from token');
        }

        // Save user ID
        currentUserId.value = userId;
        await prefs.setString('userId', userId);
        isLoggedIn.value = true;

        // Load user data
        await loadUserData(userId);

        // Navigate to profile screen and pass the userId as argument
        Get.offAllNamed('/profileScreen', arguments: userId);
        
        Get.snackbar('Success', 'Login successful');
      } catch (e) {
        print('Error decoding token: $e');
        throw Exception('Invalid token format');
      }
    } catch (e) {
      print('Login error: $e');
      Get.snackbar(
        'Login Failed',
        'Please check your credentials and try again',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(User newUser) async {
    isLoading.value = true;
    try {
      final signupData = await authRepository.signUp(newUser);
      final token = signupData["token"] as String;
      final userId = JwtUtils.getUserId(token);

      await prefs.setString('token', token);
      await prefs.setString('userId', userId);

      authToken.value = token;
      currentUserId.value = userId;
      isLoggedIn.value = true;

      await loadUserData(userId);

      Get.snackbar(
        'Succès',
        'Inscription réussie!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to profile screen and pass the userId as argument
      Get.offAllNamed('/profileScreen', arguments: userId);
    } catch (e) {
      print('Sign Up error: $e');
      if (e.toString().contains('User already exists')) {
        Get.snackbar(
          'Erreur',
          'Ce email est déjà utilisé. Veuillez essayer un autre.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Une erreur est survenue: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await prefs.clear();
      currentUserId.value = '';
      authToken.value = '';
      isLoggedIn.value = false;
      currentUser.value = null;
      Get.offAllNamed('/');
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar('Error', 'Failed to logout');
    }
  }

  // === Reset Password Flow Methods ===

  /// Sends a verification code to the given email.
  Future<bool> sendCodeToEmail(String email) async {
    isLoading.value = true;
    try {
      await authRepository.sendCodeToEmail(email);
      Get.snackbar('Success', 'Code sent to email',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      print('Send Code error: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the code entered by the user.
  Future<bool> verifyCode(String email, String code) async {
    isLoading.value = true;
    try {
      await authRepository.verifyCode(email, code);
      Get.snackbar('Success', 'Code verified',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      print('Verify Code error: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resets the password for the user.
  Future<bool> resetPassword(String email, String newPassword) async {
    isLoading.value = true;
    try {
      await authRepository.resetPassword(email, newPassword);
      Get.snackbar('Success', 'Password reset successfully',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      print('Reset Password error: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // Add to AuthController class
/*Future<void> loginWithFacebook() async {
  isLoading.value = true;
  try {
    final LoginResult result = await FacebookAuth.instance.login();
    
    if (result.status == LoginStatus.success) {
      final accessToken = result.accessToken!.token;
      final response = await authRepository.loginWithFacebook(accessToken);
      
      final token = response['token'] as String;
      final userId = JwtUtils.getUserId(token);
      
      await prefs.setString('token', token);
      await prefs.setString('userId', userId);
      
      authToken.value = token;
      currentUserId.value = userId;
      isLoggedIn.value = true;
      
      await loadUserData(userId);
      Get.offAllNamed('/profileScreen', arguments: userId);
    }
  } catch (e) {
    print('Facebook login error: $e');
    Get.snackbar(
      'Error',
      'Facebook login failed',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}*/
}
