import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class UserController extends GetxController {
  final UserDataSource _dataSource;

  // Liste des utilisateurs
  final _users = <User>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  // Utilisateur actuellement connecté
  final Rxn<User> _currentUser = Rxn<User>();

  UserController(this._dataSource);

  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  User? get currentUser =>
      _currentUser.value; // Getter pour l'utilisateur actuel

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  /// Définir l'utilisateur actuellement connecté
  void setCurrentUser(User user) {
    _currentUser.value = user;
  }

  Future<void> fetchUsers() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final results = await _dataSource.getUsers();
      _users.assignAll(results);
      print('Users fetched: ${_users.length}'); // Debugging line
    } catch (e) {
      _error.value = e.toString();
      print('Error fetching users: $e'); // Debugging line
    } finally {
      _isLoading.value = false;
    }
  }

  /// Ajouter un nouvel utilisateur
  Future<void> addUser(User user) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await _dataSource.addUser(user);
      await fetchUsers(); // Rafraîchir la liste des utilisateurs

      Get.snackbar(
        'Succès',
        'Utilisateur ajouté avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Erreur',
        'Échec de l\'ajout de l\'utilisateur: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      throw e; // Re-throw l'exception pour la gérer dans l'UI
    } finally {
      _isLoading.value = false;
    }
  }

  /// Récupérer un utilisateur spécifique par email
  Future<void> fetchCurrentUser(String email) async {
    try {
      _isLoading.value = true;
      final user = await _dataSource.getUserByEmail(email);
      _currentUser.value = user;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Mettre à jour un utilisateur
  Future<void> updateUser(User user) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await _dataSource.updateUser(user);
      await fetchUsers(); // Rafraîchir la liste des utilisateurs

      Get.snackbar(
        'Success',
        'User updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update user: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Supprimer un utilisateur
  Future<void> deleteUser(String email) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await _dataSource.deleteUser(email);
      await fetchUsers(); // Rafraîchir la liste

      Get.snackbar(
        'Success',
        'User deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to delete user: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Rechercher des utilisateurs
  void searchUsers(String query) {
    if (query.isEmpty) {
      fetchUsers();
      return;
    }

    final searchResults = _users
        .where((user) =>
            user.nom.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.phone.toLowerCase().contains(query.toLowerCase()))
        .toList();

    _users.assignAll(searchResults);
  }

  /// Trier les utilisateurs
  void sortUsers(String field, bool ascending) {
    _users.sort((a, b) {
      switch (field) {
        case 'nom':
          return ascending ? a.nom.compareTo(b.nom) : b.nom.compareTo(a.nom);
        case 'email':
          return ascending
              ? a.email.compareTo(b.email)
              : b.email.compareTo(a.email);
        case 'status':
          return ascending
              ? a.status.compareTo(b.status)
              : b.status.compareTo(a.status);
        default:
          return 0;
      }
    });
    _users.refresh();
  }

  /// Upload a user profile image
  Future<String> uploadImage(File imageFile, String email) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Upload the image and get the URL
      final imageUrl = await _dataSource.uploadImage(imageFile.path, email);

      // Check if the user exists
      try {
        final user = await _dataSource.getUserByEmail(email);
        user.imageUrl = imageUrl;
        await _dataSource.updateUser(user);
      } catch (e) {
        // If the user doesn't exist, create a new user
        final newUser = User(
          nom: '', // Provide default values or handle accordingly
          prenom: '',
          email: email,
          date: '',
          region: '',
          genre: '',
          password: '',
          phone: '',
          status: 'Active',
          imageUrl: imageUrl,
        );
        await _dataSource.addUser(newUser);
      }

      // Refresh the user list
      await fetchUsers();

      Get.snackbar(
        'Success',
        'Image uploaded successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );

      return imageUrl; // Return the uploaded image URL
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to upload image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      throw e; // Re-throw the exception to handle it in the UI
    } finally {
      _isLoading.value = false;
    }
  }

  String getUserName(String userId) {
    // Recherchez l'utilisateur dans la liste par son ID (ou email)
    final user = _users.firstWhere(
      (user) => user.email == userId,
      orElse: () => User(
        nom: 'Inconnu',
        prenom: '',
        email: '',
        date: '',
        region: '',
        genre: '',
        password: '',
        phone: '',
        status: 'Inactive',
      ),
    );

    // Retournez le nom complet de l'utilisateur
    return '${user.nom} ${user.prenom}'.trim();
  }

  Future<User> fetchUserById(String userId) async {
    try {
      _isLoading.value = true;
      final user = await _dataSource.getUserById(
          userId); // Utilisez la méthode appropriée dans UserDataSource
      return user;
    } catch (e) {
      print('Error fetching user by ID: $e');
      throw e; // Re-lancez l'exception pour la gérer dans l'appelant
    } finally {
      _isLoading.value = false;
    }
  }
}
