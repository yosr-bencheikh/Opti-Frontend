import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:opti_app/Presentation/utils/SecureStorage.dart';
import 'package:opti_app/Presentation/utils/jwt_utils.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
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
  final RxString error = ''.obs;

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
        print('Token expired');
        isLoggedIn.value = false;
        return;
      }

      final client = http.Client();
      final authDataSource = AuthRemoteDataSourceImpl(client: client);
      final authRepositoryImpl = AuthRepositoryImpl(authDataSource);
      final bool isValid = await authRepositoryImpl.verifyToken(token);
      client.close();

      if (!isValid) {
        print('Token invalid according to server');
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
      await prefs.setString('currentUser', json.encode(formattedUserData));
      await prefs.setString('userEmail', email);

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

  Future<bool> autoLogin() async {
    try {
      print("Auto-login started...");

      final String? token = prefs.getString('token');
      final String? email = prefs.getString('userEmail');

      if (token == null || email == null) {
        print("No token found. Redirecting to login.");
        return false;
      }

      print("Retrieved token: $token");
      print("Retrieved email: $email");

      // Add a timeout to prevent infinite waiting
      final isValid = await authRepository.verifyToken(token).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print("Token verification request timed out!");
          return false;
        },
      );

      if (!isValid) {
        print("Token is invalid.");
        return false;
      }

      print("Token is valid. Loading user data...");
      await loadUserData(email);

      print("Auto-login successful! Navigating to home screen.");
      return true;
    } catch (e) {
      print("Auto-login error: $e");
      return false;
    }
  }

  Future<void> _attemptTokenRefresh(String email) async {
    try {
      final String? refreshToken = prefs.getString('refreshToken');
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final newToken = await authRepository.refreshToken(refreshToken);
      await prefs.setString('token', newToken);
      await loadUserData(email);
    } catch (e) {
      await logout();
      throw Exception('Token refresh failed: $e');
    }
  }

  Future<void> loadUserFromPrefs() async {
    try {
      final String? userJson = prefs.getString('currentUser');
      final String? email = prefs.getString('userEmail');

      if (userJson == null || email == null) {
        debugPrint('No stored user data found');
        return;
      }

      try {
        final Map<String, dynamic> userData = json.decode(userJson);
        _currentUser.value = UserModel.fromJson(userData);
        debugPrint('User data loaded from prefs successfully');
      } catch (e) {
        debugPrint('Error parsing stored user data: $e');

        await prefs.remove('currentUser');
        await prefs.remove('userEmail');
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
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
      'password': data['password'] ?? '',
      if (data['_id'] != null) 'id': data['_id'],
    };
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
            'https://e263-41-62-158-98.ngrok-free.app/auth/google/callback'),
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
        // NEW: Save and register refreshToken if available
        if (responseData.containsKey('refreshToken') &&
            responseData['refreshToken'] != null) {
          final refreshToken = responseData['refreshToken'];
          await prefs.setString('refreshToken', refreshToken);
          await authRepository.refreshToken(refreshToken);
        }

        authToken.value = token;
        currentUserId.value = userId;
        isLoggedIn.value = true;
        await loadUserData(googleUser.email);
        Get.offAllNamed('/HomeScreen', arguments: userId);
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

  Future<void> loginWithFacebook() async {
    try {
      isLoading.value = true;

      await FacebookAuth.instance.logOut();

      final LoginResult result = await FacebookAuth.instance.login(
        loginBehavior: LoginBehavior.nativeOnly,
      );

      if (result.status != LoginStatus.success) {
        Get.snackbar('Cancelled', 'Facebook sign-in cancelled');
        return;
      }

      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      final response = await http.post(
        Uri.parse(
            'https://e263-41-62-158-98.ngrok-free.app/auth/facebook/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': accessToken.tokenString,
          'email': userData['email'],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final email = userData['email']; // Get the email from userData

        await prefs.setString('token', token);
        await prefs.setString('userEmail', email); // Store email in prefs

        // NEW: Save and register refreshToken if available
        if (responseData.containsKey('refreshToken') &&
            responseData['refreshToken'] != null) {
          final refreshToken = responseData['refreshToken'];
          await prefs.setString('refreshToken', refreshToken);
          await authRepository.refreshToken(refreshToken);
        }

        authToken.value = token;
        currentUserId.value =
            ''; // You can keep this empty or set it based on your logic
        isLoggedIn.value = true;

        // Load user data using the email
        await loadUserData(email); // Load user data with the email
        Get.offAllNamed('/HomeScreen',
            arguments: email); // Pass email to the profile screen
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
      final String loginResponseString =
          await authRepository.loginWithEmail(email, password);

      String token;
      String? refreshToken;

      if (loginResponseString.trim().startsWith('{')) {
        final Map<String, dynamic> loginResponse =
            json.decode(loginResponseString);
        token = loginResponse['token'];
        refreshToken = loginResponse['refreshToken'];
      } else {
        token = loginResponseString;
        refreshToken = null;
      }

      debugPrint('Login successful, token: $token');

      if (token.isEmpty) {
        throw Exception('Empty token received from server');
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String? userEmail = decodedToken['email'];
      final String? userId = decodedToken['id']?.toString();

      if (userId == null || userId.isEmpty) {
        throw Exception('Invalid token: Unable to extract user ID');
      }

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('Invalid token: Unable to extract email');
      }

      authToken.value = token;
      currentUserId.value = userId;
      isLoggedIn.value = true;

      await Future.wait([
        prefs.setString('token', token),
        prefs.setString('userId', userId),
        prefs.setString('userEmail', userEmail),
        if (refreshToken != null && refreshToken.isNotEmpty)
          prefs.setString('refreshToken', refreshToken),
      ]);

      // NEW: Register the refresh token in the database (if available)
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await authRepository.refreshToken(refreshToken);
      }

      await loadUserData(userEmail);
      Get.offAllNamed('/HomeScreen', arguments: {
        'email': userEmail,
      });
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Reset authentication state.
      authToken.value = '';
      currentUserId.value = '';
      isLoggedIn.value = false;

      await Future.wait([
        prefs.remove('token'),
        prefs.remove('userId'),
        prefs.remove('userEmail'),
        prefs.remove('refreshToken'),
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

  // Add a helper method to handle login errors
  void _handleLoginError(dynamic error) {
    authToken.value = '';
    currentUserId.value = '';
    isLoggedIn.value = false;

    SecureStorage.clearTokens();
    prefs.remove('userEmail');
    prefs.remove('userId');

    Get.snackbar(
      'Error',
      'Login failed: ${error.toString()}',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
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

      Get.offAllNamed('/login');
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

  File? selectedImage;
/*  final Rx<XFile?> _selectedImage = Rx<XFile?>(null);
  XFile? get selectedImage => _selectedImage.value;*/

  // Observable to store the uploaded image URL
  final RxString _imageUrl = ''.obs;
  String get imageUrl => _imageUrl.value;

  // Method to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
    }
  }

  Future<void> uploadImage(String email) async {
    // Vérifier si une image a été sélectionnée
    if (selectedImage == null) {
      Get.snackbar('Error', 'Aucune image sélectionnée!');
      return;
    }
    try {
      isLoading.value = true;
      final filePath =
          selectedImage!.path; // Maintenant, selectedImage n'est pas null
      print('Uploading image from path: $filePath');
      final imageUrl = await authRepository.uploadImage(filePath, email);
      print('Image uploaded successfully. URL: $imageUrl');

      // S'assurer que l'utilisateur courant existe
      if (currentUser == null) {
        throw Exception('Current user is null');
      }

      // Mettre à jour l'image de l'utilisateur
      currentUser!.imageUrl = imageUrl;
      update(); // Pour rafraîchir l'interface

      // Créer un utilisateur mis à jour avec la nouvelle image
      final updatedUser = UserModel(
        nom: currentUser!.nom,
        prenom: currentUser!.prenom,
        email: currentUser!.email,
        date: currentUser!.date,
        password: currentUser!.password,
        phone: currentUser!.phone ?? '',
        region: currentUser!.region ?? '',
        genre: currentUser!.genre ?? 'Homme',
        imageUrl: imageUrl,
      );

      // Mettre à jour côté backend
      await authRepository.updateUser(email, updatedUser);

      // Mise à jour locale de l'utilisateur courant
      _currentUser.value = updatedUser;

      // Stocker les données mises à jour dans SharedPreferences
      await prefs.setString('currentUser', json.encode(updatedUser.toJson()));

      Get.snackbar('Success', 'Image uploaded successfully!');
      Get.forceAppUpdate();
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar('Error', 'Failed to upload image: $e');
    } finally {
      isLoading.value = false;
      selectedImage = null;
    }
  }

  Future<void> updateUserProfile(String? email, User updatedUser) async {
    if (email == null) {
      throw Exception('Email cannot be null');
    }
    try {
      isLoading.value = true;
      final userToUpdate = User(
        nom: updatedUser.nom,
        prenom: updatedUser.prenom,
        email: updatedUser.email,
        date: updatedUser.date,
        phone: updatedUser.phone ?? '',
        region: updatedUser.region ?? '',
        genre: updatedUser.genre ?? 'Homme',
        // Use the current user's password if no new password is provided
        password: currentUser?.password ??
            '', // This ensures we always have a password value
        imageUrl: currentUser?.imageUrl ?? '',
      );
      await authRepository.updateUser(email, userToUpdate);
      await loadUserData(updatedUser.email);
      Get.snackbar('Success', 'Profile updated successfully');
      Get.offAllNamed('/profileScreen', arguments: userToUpdate.email);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearImage(String email) async {
    try {
      isLoading.value = true;

      // Ensure we have the current user data
      if (currentUser == null) {
        throw Exception('Current user is null');
      }

      // Call the repository method to delete the image from the database
      await authRepository.deleteUserImage(email);

      // Update the current user's imageUrl to an empty string
      currentUser!.imageUrl = ''; // Clear the image URL
      update(); // Notify GetX to rebuild

      // Create updated user with all current data minus the image
      final updatedUser = UserModel(
        nom: currentUser!.nom,
        prenom: currentUser!.prenom,
        email: currentUser!.email,
        date: currentUser!.date,
        password: currentUser!.password,
        phone: currentUser!.phone ?? '',
        region: currentUser!.region ?? '',
        genre: currentUser!.genre ?? 'Homme',
        imageUrl: '', // Set the image URL to empty
      );

      // Update in backend
      await authRepository.updateUser(email, updatedUser);

      // Directly update the current user
      _currentUser.value = updatedUser;

      // Store in SharedPreferences
      await prefs.setString('currentUser ', json.encode(updatedUser.toJson()));

      Get.snackbar('Success', 'Image cleared successfully!');
    } catch (e) {
      print('Error clearing image: $e');
      Get.snackbar('Error', 'Failed to clear image: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
