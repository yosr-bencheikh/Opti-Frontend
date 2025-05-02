import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';

import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpticianController extends GetxController {
  late final OpticianDataSource _dataSource;
  late final OpticianRepository _repository;
  late final SharedPreferences prefs;

  var opticians = <Optician>[].obs;
  final filteredOpticians = <Optician>[].obs;
  final filters = <String, String>{}.obs;

  var isLoading = true.obs;
  var isLoggedIn = false.obs;
  var error = ''.obs;
  var currentUserId = ''.obs;
  var authToken = ''.obs;
  var opticianName = "".obs;

// Ajoutez cette méthode
  bool isUserLoggedIn() {
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      isLoggedIn.value = false;
      return false;
    }

    try {
      if (JwtDecoder.isExpired(token)) {
        isLoggedIn.value = false;
        return false;
      }

      isLoggedIn.value = true;
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      return false;
    }
  }

// Modifiez onInit
  @override
  void onInit() async {
    super.onInit();

    _dataSource = Get.find<OpticianDataSource>();
    _repository = Get.find<OpticianRepository>();
    prefs = await SharedPreferences.getInstance();

    if (isUserLoggedIn()) {
      final token = prefs.getString('token')!;
      final decoded = JwtDecoder.decode(token);
      currentUserId.value = decoded['id']?.toString() ?? '';
      opticianName.value = prefs.getString('opticianName') ?? "Utilisateur";
    }

    await fetchOpticians();
    ever(filters, (_) => applyFilters());
    fetchOpticians();
  }

  void applyFilters() {
    if (opticians.isEmpty) {
      filteredOpticians.value = [];
      return;
    }

    filteredOpticians.value = opticians.where((optician) {
      // Your filter logic here
      return true; // Replace with actual filter conditions
    }).toList();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    isLoading.value = true;
    try {
      await _repository.sendPasswordResetEmail(email);
      Get.snackbar('Success', 'Reset email sent',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('Send Reset Email error: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    isLoading.value = true;
    try {
      await _repository.verifyResetCode(email, code);
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

  Future<bool> resetPassword(
      String email, String code, String newPassword) async {
    isLoading.value = true;
    try {
      await _repository.resetPassword(email, code, newPassword);
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

  void login(String userId) {
    print('🔐 Login process started');
    print('🔐 User ID received: $userId');

    currentUserId.value = userId;
    isLoggedIn.value = true;

    print('🔐 Current User ID: ${currentUserId.value}');
    print('🔐 Is Logged In: $isLoggedIn');
  }

// Ajouter une méthode de déconnexion
  void logout() async {
    authToken.value = '';
    currentUserId.value = '';
    isLoggedIn.value = false;
    opticianName.value = '';

    // Effacer toutes les données stockées
    await prefs.remove('token');
    await prefs.remove('userEmail');
    await prefs.remove('opticianName');

    // Afficher un message de confirmation
    Get.snackbar(
      'Succès',
      'Vous avez été déconnecté avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Rediriger vers la page de connexion
    Get.offAllNamed('/LoginOpticien'); // Assurez-vous que cette route existe
  }

  String? getOpticienNom(String? opticienId) {
    if (opticienId == null) return null;
    final optician =
        opticians.firstWhereOrNull((opticien) => opticien.id == opticienId);
    return optician != null ? '${optician.nom} ${optician.prenom}' : null;
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      final token = await _repository.loginWithEmail(email, password);

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['id']?.toString() ?? '';

      // Récupérer les informations de l'opticien
      final Optician optician = await _dataSource.getOpticianByEmail(email);

      // Save user ID, token, and optician first name (prenom)
      currentUserId.value = userId;
      authToken.value = token;
      isLoggedIn.value = true;
      opticianName.value = optician.prenom;

      // Récupérer les boutiques de l'opticien connecté
      final boutiqueController = Get.find<BoutiqueController>();
      await boutiqueController
          .getboutiqueByOpticianId(userId); // Nouvelle méthode

      // Save token, email, and optician first name to SharedPreferences
      await prefs.setString('token', token);
      await prefs.setString('userEmail', email);
      await prefs.setString('opticianName', opticianName.value);

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
  Future<void> addOptician(Optician optician, {PlatformFile? imageFile}) async {
    try {
      isLoading(true);
      error('');

      // Upload image first if exists
      String imageUrl = '';
      if (imageFile != null) {
        if (kIsWeb) {
          imageUrl = await uploadImageWeb(
            imageFile.bytes!,
            imageFile.name,
            optician.email,
          );
        } else {
          imageUrl = await uploadImage(
            File(imageFile.path!),
            optician.email,
          );
        }
      }

      // Create optician with image URL
      final newOptician = optician.copyWith(imageUrl: imageUrl);

      // Add to local list immediately
      opticians.insert(0, newOptician);

      // Push to backend
      await _dataSource.addOptician(newOptician);

      Get.snackbar('Success', 'Optician added successfully');
    } catch (e) {
      // Remove from local list if failed
      opticians.removeWhere((o) => o.email == optician.email);
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
      final filePath = imageFile.absolute.path;
      final imageUrl = await _dataSource.uploadImage(filePath, email);

      // Update local optician
      final index = opticians.indexWhere((o) => o.email == email);
      if (index != -1) {
        final updated = opticians[index].copyWith(imageUrl: imageUrl);
        opticians[index] = updated;
      }

      return imageUrl;
    } catch (e) {
      print('Image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String email) async {
    try {
      final imageUrl =
          await _dataSource.uploadImageWeb(imageBytes, fileName, email);

      // Update local optician
      final index = opticians.indexWhere((o) => o.email == email);
      if (index != -1) {
        final updated = opticians[index].copyWith(imageUrl: imageUrl);
        opticians[index] = updated;
      }

      return imageUrl;
    } catch (e) {
      print('Web image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }
}

