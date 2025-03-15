// Presentation/controllers/OpticianController.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/data/repositories/OpticianRepositoryImpl.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpticianController extends GetxController {
  final OpticianDataSource _dataSource = OpticianDataSourceImpl();
  late final OpticianRepository opticienRepository;
  late final SharedPreferences prefs;
  var opticians = <Optician>[].obs; // Observable list of opticians
  var isLoading = true.obs; // Loading state
  var isLoggedIn = false.obs;
  var error = ''.obs; // Error message
  var currentUserId = ''.obs;
  var authToken = ''.obs;
  var opticianName = "".obs;

  @override
  void onInit() async {
    super.onInit();

    // Initialiser SharedPreferences
    prefs = await SharedPreferences.getInstance();

    // Initialiser le repository
    opticienRepository = OpticianRepositoryImpl(_dataSource);

    // Vérifier si l'utilisateur est déjà connecté
    final storedToken = prefs.getString('token');
    final storedEmail = prefs.getString('userEmail');
    final storedOpticianName = prefs.getString('opticianName');

    if (storedToken != null && storedToken.isNotEmpty) {
      authToken.value = storedToken;
      isLoggedIn.value = true;

      // Vérifier si le token est valide (non expiré)
      try {
        if (JwtDecoder.isExpired(storedToken)) {
          // Token expiré, déconnexion
          logout();
        } else {
          // Token valide, récupérer les informations de l'utilisateur
          final Map<String, dynamic> decodedToken =
              JwtDecoder.decode(storedToken);
          currentUserId.value = decodedToken['id']?.toString() ?? '';

          // Charger le nom de l'opticien
          opticianName.value = storedOpticianName ?? "Utilisateur";

          // Rediriger vers le dashboard si nécessaire
          if (Get.currentRoute != '/OpticienDashboard') {
            Get.offAllNamed('/OpticienDashboard',
                arguments: currentUserId.value);
          }
        }
      } catch (e) {
        // Erreur de décodage du token, déconnexion
        logout();
      }
    }

    // Charger les opticiens
    fetchOpticians();
  }

// Ajouter une méthode de déconnexion
  void logout() async {
    authToken.value = '';
    currentUserId.value = '';
    isLoggedIn.value = false;
    await prefs.remove('token');
    await prefs.remove('userEmail');
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      final token = await opticienRepository.loginWithEmail(email, password);

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['id']?.toString() ?? '';

      // Récupérer les informations de l'opticien
      final Optician optician = await _dataSource.getOpticianByEmail(email);

      // Save user ID, token, and optician first name (prenom)
      currentUserId.value = userId;
      authToken.value = token;
      isLoggedIn.value = true;
      opticianName.value = optician.prenom; // Utiliser le prénom ici

      // Save token, email, and optician first name to SharedPreferences
      await prefs.setString('token', token);
      await prefs.setString('userEmail', email);
      await prefs.setString(
          'opticianName', opticianName.value); // Stocker le prénom

      // Load user data
      await fetchOpticians();

      // Navigate to home screen
      Get.offAllNamed('/OpticienDashboard', arguments: userId);
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

  Future<void> loadOpticianName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    opticianName.value = prefs.getString('opticianName') ?? "Utilisateur";
  }

  // Fetch all opticians
  Future<void> fetchOpticians() async {
    try {
      isLoading(true); // Set loading to true
      error(''); // Clear any previous errors
      final result = await _dataSource.getOpticians(); // Fetch data
      opticians.assignAll(result); // Update the observable list
    } catch (e) {
      error(e.toString()); // Set error message
      Get.snackbar('Error', 'Failed to fetch opticians: ${e.toString()}');
    } finally {
      isLoading(false); // Set loading to false
    }
  }

  // Add a new optician
  Future<void> addOptician(Optician optician) async {
    try {
      isLoading(true);
      error('');
      await _dataSource
          .addOptician(optician); // Add optician to the data source
      Get.snackbar('Success', 'Optician added successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to add optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Update an existing optician
  Future<void> updateOptician(Optician optician) async {
    try {
      isLoading(true);
      error('');
      await _dataSource
          .updateOptician(optician); // Update optician in the data source
      Get.snackbar('Success', 'Optician updated successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to update optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Delete an optician
  Future<void> deleteOptician(String id) async {
    try {
      isLoading(true);
      error('');
      await _dataSource
          .deleteOptician(id); // Delete optician from the data source
      Get.snackbar('Success', 'Optician deleted successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to delete optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  int getTotalOpticians() {
    return opticians.length;
  }

  Future<String> uploadImage(File imageFile, String email) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('File does not exist');
      }

      // Use more robust file path handling
      final filePath = imageFile.absolute.path;

      // Perform image upload
      final imageUrl = await _dataSource.uploadImage(filePath, email);

      // Update optician logic
      try {
        final optician = await _dataSource.getOpticianByEmail(email);
        optician.imageUrl = imageUrl;
        await _dataSource.updateOptician(optician);
      } catch (e) {
        // Handle optician not found scenario
        print('Optician not found, creating new optician: $e');
        final newOptician = Optician(
          id: '', // Generate a unique ID if needed
          nom: '',
          prenom: '',
          email: email,
          date: '',
          genre: '',
          password: '',
          address: '',
          phone: '',
          region: '',
          imageUrl: imageUrl,
        );
        await _dataSource.addOptician(newOptician);
      }

      // Refresh opticians list
      await fetchOpticians();

      // Use context-aware snackbar or alternative notification
      return imageUrl;
    } catch (e) {
      print('Image upload error: $e');
      // Consider a more robust error handling mechanism
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String email) async {
    try {
      final imageUrl =
          await _dataSource.uploadImageWeb(imageBytes, fileName, email);

      try {
        final optician = await _dataSource.getOpticianByEmail(email);
        optician.imageUrl = imageUrl;
        await _dataSource.updateOptician(optician);
      } catch (e) {
        print('Optician not found, creating new optician: $e');
        final newOptician = Optician(
          id: '',
          nom: '',
          prenom: '',
          email: email,
          date: '',
          genre: '',
          password: '',
          address: '',
          phone: '',
          region: '',
          imageUrl: imageUrl,
        );
        await _dataSource.addOptician(newOptician);
      }

      await fetchOpticians();
      return imageUrl;
    } catch (e) {
      print('Web image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }
}
