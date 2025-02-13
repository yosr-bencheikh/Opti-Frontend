import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:opti_app/Presentation/utils/jwt_utils.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/Presentation/utils/jwt_utils.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final SharedPreferences prefs;

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var currentUserId = ''.obs;
  final Rx<User?> _currentUser = Rx<User?>(null); // Private variable
  var authToken = ''.obs;

  AuthController({
    required this.authRepository,
    required this.prefs,
  });

  // Getter and setter for currentUser
  User? get currentUser => _currentUser.value;
  set currentUser(User? value) => _currentUser.value = value;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    ever(isLoggedIn, handleAuthenticationChanged);
    checkLoginStatus();
  }
    void handleAuthenticationChanged(bool isLoggedIn) {
    if (isLoggedIn) {
      Get.offAllNamed('/profileScreen', arguments: currentUserId.value);
    } else {
      Get.offAllNamed('/login');
    }
  }


Future checkLoginStatus() async {
  try {
    final String? token = prefs.getString('token');
    final String? userId = prefs.getString('userId');
    
    if (token == null || userId == null) {
      await logout();
      return;
    }
    
    // Vérifier si le token est expiré localement
    if (JwtDecoder.isExpired(token)) {
      print('Token expiré');
      await logout();
      return;
    }
    
    // Create an HTTP client
    final client = http.Client();
    
    // Create AuthRemoteDataSource with the required client
    final authDataSource = AuthRemoteDataSourceImpl(client: client);
    
    // Create AuthRepositoryImpl with the correct data source
    final authRepositoryImpl = AuthRepositoryImpl(authDataSource);
    
    // Vérifier le token avec le serveur
    final bool isValid = await authRepositoryImpl.verifyToken(token);
    if (!isValid) {
      print('Token invalide selon le serveur');
      await logout();
      return;
    }
    
    // Don't forget to close the client when done
    client.close();
    
  } catch (e) {
    await logout();
    print('Error in checkLoginStatus: $e');
  }
}

 Future<void> loadUserData(String userId) async {
  try {
    print('Loading user data for ID: $userId');
    print('User ID format check: ${userId.length} characters: $userId');
     // Add this
    final userData = await authRepository.getUser(userId);

    if (userData == null) {
      print('Null response from server');
      throw Exception('Server returned null');
    }

    print('Received user data: ${userData.toString()}');
    currentUser = User.fromJson(userData);
  } catch (e) {
    print('loadUserData ERROR: ${e.toString()}');
    // Check if we're getting a response at all
  
  
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
        

        // Navigate to profile screen and pass the userId as argument
        Get.offAllNamed('/profileScreen', arguments: userId);
         await loadUserData(userId);

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
      currentUser = null; // Use the setter
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

  Future<void> uploadImage(String userId) async {
    try {
      final filePath = _selectedImage.value!.path;
      final imageUrl = await authRepository.uploadImage(filePath, userId);

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
      await authRepository.updateUser(userId, updatedUser);

      // Refresh the current user data
      await loadUserData(userId);

      Get.snackbar('Success', 'Image uploaded successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }
}