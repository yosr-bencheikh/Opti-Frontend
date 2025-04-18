import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

import 'package:opti_app/Presentation/utils/jwt_utils.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final SharedPreferences prefs;
  final ProductController productController = Get.find();
  List<bool> favorites = [];
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        "95644263598-p1ko0g4ds7ko6v6obqkdc38j76ndjmt2.apps.googleusercontent.com",
  );
  final secureStorage = FlutterSecureStorage();

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  // Observable for storing the auto-generated user id from the backend
  var currentUserId = ''.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);
  var authToken = ''.obs;
  final RxString error = ''.obs;
  final List<User> users = []; // or List<UserModel> users = [];

  User? get currentUser => _currentUser.value;
  set currentUser(User? value) => _currentUser.value = value;
  final NotificationService notificationService = NotificationService();

  // Constructor with named parameters
  AuthController({
    required this.authRepository,
    required this.prefs,
  });

  @override
  void onInit() {
    super.onInit();
    notificationService.initialize();
    loadUserFromPrefs();
    favorites =
        List.generate(productController.products.length, (index) => false);
  }

  void toggleFavorite(int index) {
    favorites[index] = !favorites[index];
  }

  Future<void> debugSharedPrefs() async {
    final keys = prefs.getKeys();
    print("All keys in SharedPreferences: $keys");

    final token = prefs.getString('token');
    print("Token in prefs: $token");

    final email = prefs.getString('userEmail');
    print("Email in prefs: $email");
  }

  void handleAuthenticationChanged(bool loggedIn) {
    if (loggedIn) {
      Future.microtask(() =>
          Get.offAllNamed('/profileScreen', arguments: currentUserId.value));
    } else {
      Future.microtask(() => Get.offAllNamed('/login'));
    }
  }

  Future<void> checkLoginStatus() async {
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

  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      final userData = await authRepository.getUserByEmail(email);
      return userData;
    } catch (e) {
      print('Error getting user by email: $e');
      throw e;
    }
  }

  /// Updated loadUserData using the repository's function instead of a direct HTTP call.
  Future<void> loadUserData(String email) async {
    try {
      isLoading.value = true;
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      debugPrint('Fetching user data for email: $email');
      // Call the repository method to get user data by email.
      final Map<String, dynamic> userData =
          await authRepository.getUserByEmail(email);

      // Retrieve the auto-generated id (under 'id' or '_id')
      currentUserId.value = userData['id'] ?? userData['_id'] ?? '';

      debugPrint('User ID retrieved: ${currentUserId.value}');
      _currentUser.value = UserModel.fromJson(userData);

      await prefs.setString('currentUser', json.encode(userData));
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

      // First check if we already have a currentUser in memory
      if (_currentUser.value != null && authToken.value.isNotEmpty) {
        print("User already loaded in memory");
        isLoggedIn.value = true;
        return true;
      }
      final allKeys = prefs.getKeys();
      print("All keys in SharedPreferences: $allKeys");
      // Then check SharedPreferences

      final String? email = prefs.getString('userEmail');
      final String? token = await secureStorage.read(key: 'token');

      // Debug info
      print("Token from SharedPreferences: ${token?.substring(0, 10)}...");
      print("Email from SharedPreferences: $email");

      // Verify token exists
      if (token == null || email == null) {
        print("No token or email found. Redirecting to login.");
        return false;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        print("Token is expired. Attempting to refresh...");
        try {
          await _attemptTokenRefresh(email);
          if (authToken.value.isEmpty) {
            print("Token refresh failed.");
            return false;
          }
        } catch (e) {
          print("Token refresh error: $e");
          return false;
        }
      } else {
        // Store the valid token
        authToken.value = token;
      }

      // Load user data
      try {
        print("Token is valid. Loading user data...");
        await loadUserData(email);

        // Update auth status
        isLoggedIn.value = true;

        // Set OneSignal external user ID if available
        if (currentUserId.value.isNotEmpty) {
          await notificationService.setExternalUserId(currentUserId.value);
        }

        print("Auto-login successful!");
        return true;
      } catch (e) {
        print("Error loading user data: $e");
        return false;
      }
    } catch (e) {
      print("Auto-login error: $e");
      return false;
    }
  }

  Future<void> _attemptTokenRefresh(String email) async {
    try {
      final String? refreshToken = prefs.getString('refreshToken');
      if (refreshToken == null) return;

      final newToken = await authRepository.refreshToken(refreshToken);
      await prefs.setString('token', newToken);
      await loadUserData(email);
    } catch (e) {
      await logout();
    }
  }

  Future<UserModel?> fetchAndStoreUser(String userId) async {
    try {
      // Fetch user data as a Map
      final userData = await authRepository.getUserById(userId);

      // Convert the Map to a User object
      final user = UserModel.fromJson(
          userData); // Assuming userData is a Map<String, dynamic>

      // Log the fetched user ID
      print("User  fetched: ${user.id}"); // Now this should work

      // Return the User object
      return user;
    } catch (e) {
      print('Error fetching user: $e');
      return null; // Return null in case of an error
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
        currentUserId.value = userData['id'] ?? userData['_id'] ?? '';
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

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Get.snackbar('Cancelled', 'Google sign-in cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await http.post(
        Uri.parse('https://your-api-url/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final decodedToken = JwtDecoder.decode(token);
        final email = decodedToken['email'] as String;
        final userId = decodedToken['userId']?.toString() ?? '';

        await prefs.setString('token', token);
        await prefs.setString('userId', userId);
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

      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        Get.snackbar('Cancelled', 'Facebook login cancelled');
        return;
      }

      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      final response = await http.post(
        Uri.parse('https://your-api-url/auth/facebook/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'token': accessToken.tokenString, 'email': userData['email']}),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final email = userData['email'];

        await prefs.setString('token', token);
        await prefs.setString('userEmail', email);

        if (responseData.containsKey('refreshToken') &&
            responseData['refreshToken'] != null) {
          final refreshToken = responseData['refreshToken'];
          await prefs.setString('refreshToken', refreshToken);
          await authRepository.refreshToken(refreshToken);
        }

        authToken.value = token;
        isLoggedIn.value = true;
        await loadUserData(email);
        Get.offAllNamed('/HomeScreen', arguments: email);
      } else if (response.statusCode == 409) {
        throw Exception(responseBody['error']);
      } else {
        throw Exception('Error: ${responseBody['message']}');
      }
    } catch (error) {
      print("Complete error: ${error.toString()}");
      if (error.toString().contains('E11000')) {
        Get.snackbar(
          'Email Exists',
          'This email is already linked to an account. Please use another email.',
          backgroundColor: const Color.fromARGB(255, 246, 65, 65),
          duration: Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Facebook Error',
          error.toString().replaceAll('Exception: ', ''),
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      final token = await authRepository.loginWithEmail(email, password);

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['id']?.toString() ?? '';

      // Save user ID and token
      currentUserId.value = userId;
      authToken.value = token;
      isLoggedIn.value = true;

      await prefs.setString('token', token);
      print(
          "Token saved in SharedPreferences: ${prefs.getString('token')}"); // Verify it was saved
      await prefs.setString('userEmail', email);
      await prefs.setString('userId', userId);
      print("SharedPreferences keys after saving: ${prefs.getKeys()}");
      await secureStorage.write(key: 'token', value: token);

      // Set external user ID for OneSignal
      await notificationService.setExternalUserId(userId);
      OneSignal.login(userId);

      // Load user data
      await loadUserData(email);

      // Navigate to home screen
      Get.offAllNamed('/HomeScreen', arguments: userId);
    } catch (e) {
      debugPrint('Login error: $e');
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
      // Call the repository to sign up
      final signupData = await authRepository.signUp(newUser);

      // Extract token and user ID
      final token = signupData["token"] as String;
      final String userId = signupData["userId"] as String;

      // Save user ID and token
      currentUserId.value = userId;
      authToken.value = token;
      isLoggedIn.value = true;

      // Set external user ID for OneSignal
      await notificationService.setExternalUserId(userId);

      // Load user data
      await loadUserData(newUser.email);

      // Navigate to home screen
      Get.offAllNamed('/HomeScreen', arguments: newUser.email);
    } catch (e) {
      debugPrint('Sign Up error: $e');
      Get.snackbar(
        'Error',
        'Signup failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
      _currentUser.value = null;

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

  final RxString _imageUrl = ''.obs;
  String get imageUrl => _imageUrl.value;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);
    }
  }

  Future<void> uploadImage(String email) async {
    if (selectedImage == null) {
      Get.snackbar('Error', 'No image selected!');
      return;
    }
    try {
      isLoading.value = true;
      final filePath = selectedImage!.path;
      print('Uploading image from path: $filePath');
      final imageUrl = await authRepository.uploadImage(filePath, email);
      print('Image uploaded successfully. URL: $imageUrl');

      if (currentUser == null) {
        throw Exception('Current user is null');
      }

      currentUser!.imageUrl = imageUrl;
      update();

      final updatedUser = UserModel(
        nom: currentUser!.nom,
        prenom: currentUser!.prenom,
        email: currentUser!.email,
        date: currentUser!.date,
        password: currentUser!.password,
        phone: currentUser!.phone,
        region: currentUser!.region,
        genre: currentUser!.genre,
        imageUrl: imageUrl,
        refreshTokens: currentUser!.refreshTokens,
      );

      await authRepository.updateUser(email, updatedUser);
      _currentUser.value = updatedUser;
      await prefs.setString('currentUser', json.encode(updatedUser.toJson()));
      Get.snackbar('Success', 'Image uploaded successfully!');
      Get.forceAppUpdate();
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar('Error', 'Failed to upload image: $e');
    } finally {
      isLoading.value = false;
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
        region: updatedUser.region,
        genre: updatedUser.genre,
        phone: updatedUser.phone,
        password: currentUser?.password ?? '',
        imageUrl: currentUser?.imageUrl ?? '',
        refreshTokens: updatedUser.refreshTokens,
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

  Future<void> updateProfile(
    String name,
    String prenom,
    String date,
    String region,
    String phone,
    String email,
  ) async {
    // Build the updated user object.
    // Use currentUser’s genre, password, imageUrl, and refreshTokens if available,
    // or provide default values.
    final updatedUser = User(
      nom: name,
      prenom: prenom,
      email: email,
      date: date,
      region: region,
      genre: currentUser?.genre ?? '',
      phone: phone,
      password: currentUser?.password ?? '',
      imageUrl: currentUser?.imageUrl ?? '',
      refreshTokens: currentUser!.refreshTokens,
    );

    // Call the existing updateUserProfile method which handles the update
    await updateUserProfile(email, updatedUser);
  }

  Future<void> clearImage(String email) async {
    try {
      isLoading.value = true;
      if (currentUser == null) {
        throw Exception('Current user is null');
      }
      await authRepository.deleteUserImage(email);
      currentUser!.imageUrl = '';
      update();
      final updatedUser = UserModel(
        nom: currentUser!.nom,
        prenom: currentUser!.prenom,
        email: currentUser!.email,
        date: currentUser!.date,
        password: currentUser!.password,
        phone: currentUser!.phone,
        region: currentUser!.region,
        genre: currentUser!.genre,
        imageUrl: '',
        refreshTokens: currentUser!.refreshTokens,
      );
      await authRepository.updateUser(email, updatedUser);
      _currentUser.value = updatedUser;
      await prefs.setString('currentUser', json.encode(updatedUser.toJson()));
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
