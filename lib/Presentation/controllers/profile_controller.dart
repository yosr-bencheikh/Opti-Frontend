import 'package:flutter/material.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/usecases/get_user_usecase.dart';
import 'package:opti_app/domain/usecases/update_user.dart';

class ProfileController extends ChangeNotifier {
  final GetUser getUser;
  final UpdateUser updateUser;

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileController({
    required this.getUser,
    required this.updateUser,
  });

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await getUser(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUser(String userId, User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await updateUser(userId, user);
      _user = user;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}