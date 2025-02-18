import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:opti_app/Presentation/utils/jwt_utils.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final SharedPreferences prefs;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        "95644263598-p1ko0g4ds7ko6v6obqkdc38j76ndjmt2.apps.googleusercontent.com",
  );

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUserId = ''.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);
  var authToken = ''.obs;

  AuthController({
    required this.authRepository,
    required this.prefs,
  });

  User? get currentUser => _currentUser.value;
  set currentUser(User? value) => _currentUser.value = value;

  @override
  void onInit() {
    super.onInit();
    loadUserFromPrefs();
  }

  void handleAuthenticationChanged(bool isLoggedIn) {
    if (isLoggedIn) {
      Future.microtask(() =>
          Get.offAllNamed('/profileScreen', arguments: currentUserId.value));
    } else {
      Future.microtask(() => Get.offAllNamed('/login'));
    }
  }

  Future checkLoginStatus() async {
    try {
      final String? token = prefs.getString('token');
      final String? userId = prefs.getString('userId');

      if (token == null || userId == null) {
        isLoggedIn.value = false;
        return;
      }

      if (JwtDecoder.isExpired(token)) {
        print('Token expiré');
        isLoggedIn.value = false;
        return;
      }

      final client = http.Client();
      final authDataSource = AuthRemoteDataSourceImpl(client: client);
      final authRepositoryImpl = AuthRepositoryImpl(authDataSource);
      final bool isValid = await authRepositoryImpl.verifyToken(token);
      client.close();

      if (!isValid) {
        print('Token invalide selon le serveur');
        isLoggedIn.value = false;
        return;
      }

      currentUserId.value = userId;
      isLoggedIn.value = true;
    } catch (e) {
      isLoggedIn.value = false;
      print('Error in checkLoginStatus: $e');
    }
  }

  Map<String, dynamic> _formatUserData(Map<String, dynamic> data) {
    return {
      'nom': data['nom'] ?? '',
      'prenom': data['prenom'] ?? '',
      'email': data['email'] ?? '',
      'date': data['date'] ?? '',
      'phone': data['phone'] ?? '',
      'region': data['region'] ?? '',
      'genre': data['genre'] ?? 'Homme',
      'imageUrl': data['imageUrl'] ?? '',
      'password': data['password'] ?? '', // Include password if available
    };
  }

  Future<void> loadUserData(String email) async {
    try {
      isLoading.value = true;
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      debugPrint('Fetching user data for email: $email');
      final userData = await authRepository.getUserByEmail(email);

      if (userData == null) {
        throw Exception('User data not found for email: $email');
      }

      debugPrint('Raw user data received: $userData');
      final formattedUserData = _formatUserData(userData);
      debugPrint('Formatted user data: $formattedUserData');

      // Create a UserModel instance from the formatted data
      _currentUser.value = UserModel.fromJson(formattedUserData);

      // Store the current user data
      await prefs.setString(
          'currentUser_$email', json.encode(formattedUserData));
      await prefs.setString('lastLoggedInEmail', email);

      debugPrint('User data loaded and stored successfully');
    } catch (e) {
      debugPrint('Error loading user data: $e');
      Get.snackbar(
        'Error',
        'Failed to load user data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

// Load user data from SharedPreferences on app start
  Future<void> loadUserFromPrefs() async {
    try {
      final String? lastEmail = prefs.getString('lastLoggedInEmail');
      if (lastEmail == null) return;

      final String? userJson = prefs.getString('currentUser_$lastEmail');
      if (userJson != null) {
        final Map<String, dynamic> userData = json.decode(userJson);
        _currentUser.value = User.fromJson(userData);
      }
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await _googleSignIn.signOut(); // Force account selection

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Get.snackbar('Cancelled', 'Google sign-in cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await http.post(
        Uri.parse(
            'https://0b60-197-3-209-201.ngrok-free.app/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final userId = JwtDecoder.decode(token)['userId'].toString();

        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        authToken.value = token;
        currentUserId.value = userId;
        isLoggedIn.value = true;
        await loadUserData(googleUser.email);
        Get.offAllNamed('/profileScreen', arguments: userId);
      } else {
        throw Exception('Google login failed: ${response.body}');
      }
    } catch (error) {
      Get.snackbar(
        'Error',
        'Google login failed: ${error.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Facebook Sign-In
  Future<void> loginWithFacebook() async {
    try {
      isLoading.value = true;
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        Get.snackbar('Cancelled', 'Facebook sign-in cancelled');
        return;
      }

      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      final response = await http.post(
        Uri.parse(
            'https://0b60-197-3-209-201.ngrok-free.app/auth/facebook/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': accessToken.tokenString,
          'email': userData['email'],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final userId = JwtDecoder.decode(token)['userId'].toString();

        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        authToken.value = token;
        currentUserId.value = userId;
        isLoggedIn.value = true;

        Get.offAllNamed('/profileScreen', arguments: userId);
      } else {
        throw Exception('Facebook login failed: ${response.body}');
      }
    } catch (error) {
      Get.snackbar(
        'Error',
        'Facebook login failed: ${error.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password');
      return;
    }

    isLoading.value = true;

    try {
      debugPrint('Calling loginWithEmail function...');
      final response = await authRepository.loginWithEmail(email, password);
      debugPrint('Server Response: $response');

      if (response.isEmpty) {
        throw Exception('Empty response received from server');
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(response);
      final String? userEmail = decodedToken['email'];
      final String? userId = decodedToken['id']?.toString();

      if (userId == null || userId.isEmpty) {
        throw Exception('Invalid token: Unable to extract user ID');
      }

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('Invalid token: Unable to extract email');
      }

      // Store authentication data
      authToken.value = response;
      currentUserId.value = userId;
      isLoggedIn.value = true;

      await Future.wait([
        prefs.setString('token', response),
        prefs.setString('userId', userId),
        prefs.setString('userEmail', userEmail),
      ]);

      await loadUserData(userEmail);
      Get.offAllNamed('/profileScreen', arguments: {
        'email': userEmail,
      });
    } catch (e, stackTrace) {
      print('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      authToken.value = '';
      currentUserId.value = '';
      isLoggedIn.value = false;

      await Future.wait([
        prefs.remove('token'),
        prefs.remove('userId'),
        prefs.remove('userEmail'),
      ]);

      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
      final email = JwtUtils.getEmailFromToken(token);

      await prefs.setString('token', token);
      await prefs.setString('userEmail', email);

      authToken.value = token;

      isLoggedIn.value = true;

      await loadUserData(email);

      Get.snackbar(
        'Succès',
        'Inscription réussie!',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed('/profileScreen', arguments: email);
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
      final GoogleSignIn googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
      } catch (e) {
        print('Google signOut error: $e');
      }
      try {
        await googleSignIn.disconnect();
      } catch (e) {
        print('Google disconnect error: $e');
      }

      currentUserId.value = '';
      authToken.value = '';
      isLoggedIn.value = false;
      currentUser = null;

      Get.offAllNamed('/loginScreen');
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

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

  final Rx<XFile?> _selectedImage = Rx<XFile?>(null);
  XFile? get selectedImage => _selectedImage.value;

  // Observable to store the uploaded image URL
  final RxString _imageUrl = ''.obs;
  String get imageUrl => _imageUrl.value;

  // Method to pick an image from the gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImage.value = image;
    }
  }

  Future<void> uploadImage(String email) async {
    try {
      final filePath = _selectedImage.value!.path;
      print('Uploading image from path: $filePath');
      final imageUrl = await authRepository.uploadImage(filePath, email);
      print('Image uploaded successfully. URL: $imageUrl');

      // Update the user's imageUrl in the backend
      final updatedUser = User(
        nom: currentUser!.nom,
        prenom: currentUser!.prenom,
        email: currentUser!.email,
        date: currentUser!.date,
        password: currentUser!.password,
        phone: currentUser!.phone,
        region: currentUser!.region,
        genre: currentUser!.genre,
        imageUrl: imageUrl, // Update the imageUrl
      );

      // Save the updated user to the backend
      await authRepository.updateUser(email, updatedUser);

      // Refresh the current user data
      await loadUserData(email);

      Get.snackbar('Success', 'Image uploaded successfully!');
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }

  Future<void> updateUserProfile(String email, User updatedUser) async {
    try {
      isLoading.value = true;

      // Use the email as is (no encoding)
      final encodedEmail = email; // Remove the encoding

      // Create a complete user object with all required fields
      final userToUpdate = User(
          nom: updatedUser.nom,
          prenom: updatedUser.prenom,
          email: updatedUser.email,
          date: updatedUser.date,
          phone: updatedUser.phone ??
              '', // Provide default values for optional fields
          region: updatedUser.region ?? '',
          genre: updatedUser.genre ?? 'Homme',
          password: updatedUser.password, // Only included if changed
          imageUrl: currentUser?.imageUrl ?? '' // Preserve existing image URL
          );

      // Call repository to update user
      await authRepository.updateUser(encodedEmail, userToUpdate);

      // Reload user data to ensure UI is in sync
      await loadUserData(updatedUser.email);

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate using the new email in case it was updated
      Get.offAllNamed('/profileScreen', arguments: userToUpdate.email);
    } catch (e) {
      print('Update profile error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
