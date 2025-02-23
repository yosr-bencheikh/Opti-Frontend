import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';

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
  User? get currentUser => _currentUser.value; // Getter pour l'utilisateur actuel

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  /// Définir l'utilisateur actuellement connecté
  void setCurrentUser(User user) {
    _currentUser.value = user;
  }

  /// Récupérer les utilisateurs depuis le backend
  Future<void> fetchUsers() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final results = await _dataSource.getUsers();
      _users.assignAll(results);
    } catch (e) {
      _error.value = e.toString();
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

    final searchResults = _users.where((user) =>
        user.nom.toLowerCase().contains(query.toLowerCase()) ||
        user.email.toLowerCase().contains(query.toLowerCase()) ||
        user.phone.toLowerCase().contains(query.toLowerCase())
    ).toList();

    _users.assignAll(searchResults);
  }

  /// Trier les utilisateurs
  void sortUsers(String field, bool ascending) {
    _users.sort((a, b) {
      switch (field) {
        case 'nom':
          return ascending ? a.nom.compareTo(b.nom) : b.nom.compareTo(a.nom);
        case 'email':
          return ascending ? a.email.compareTo(b.email) : b.email.compareTo(a.email);
        case 'status':
          return ascending ? a.status.compareTo(b.status) : b.status.compareTo(a.status);
        default:
          return 0;
      }
    });
    _users.refresh();
  }
}
