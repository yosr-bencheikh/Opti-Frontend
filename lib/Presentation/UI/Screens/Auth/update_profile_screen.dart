import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String email;

  const UpdateProfileScreen({
    super.key,
    required this.email,
  });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _dateNaissanceController;
  String? _selectedRegion;
  String? _selectedGenre;
  bool _isLoading = false;
  User? _currentUser;

  final AuthController _authController = Get.find<AuthController>();
  final List<String> _genres = ['Homme', 'Femme'];
  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateNaissanceController = TextEditingController();
    _selectedGenre = 'Homme';

    debugPrint('Initial email: ${widget.email}'); // Add this log

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.email.isEmpty) {
        debugPrint('Email is empty!');
        Get.snackbar(
          'Error',
          'Email is required',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
      } else {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      User? user = _authController.currentUser;

      if (user == null) {
        debugPrint('Loading user data for email: ${widget.email}');
        await _authController.loadUserData(widget.email);
        user = _authController.currentUser;
      }

      if (user == null) {
        throw Exception('User data not found');
      }

      debugPrint('User data loaded successfully: ${user.toJson()}');

      if (mounted) {
        setState(() {
          _currentUser = user;
          _nomController.text = user!.nom;
          _prenomController.text = user.prenom;
          _emailController.text = user.email;
          _dateNaissanceController.text = user.date;
          _selectedRegion = user.region;
          _selectedGenre = user.genre.isNotEmpty ? user.genre : 'Homme';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load user data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Make sure we're using the correct email
      final email = widget.email; // This should be the current user's email

      final updatedUser = UserModel(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController
            .text, // This can be different if user is changing their email
        date: _dateNaissanceController.text,
        region: _selectedRegion ?? '',
        genre: _selectedGenre ?? 'Homme',
        password: _currentUser!.password,
        phone: _currentUser!.phone,
      );

      debugPrint('Updating profile with email: $email');
      debugPrint('Update payload: ${updatedUser.toJson()}');

      await _authController.updateUserProfile(email, updatedUser);

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back(result: true);
    } catch (e) {
      debugPrint('Update profile error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile. Please check your information and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _dateNaissanceController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le profil'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateNaissanceController,
                    decoration: const InputDecoration(
                      labelText: 'Date de naissance',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre date de naissance';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                ),
                items: _genres.map((String genre) {
                  return DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGenre = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner votre genre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Mettre à jour le profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _dateNaissanceController.dispose();
    super.dispose();
  }
}
