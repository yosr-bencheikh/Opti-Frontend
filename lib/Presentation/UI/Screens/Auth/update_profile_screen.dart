import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String userId;

  const UpdateProfileScreen({
    super.key,
    required this.userId,
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

  // Initialize repository
  final AuthRepository _authRepository =
      AuthRepositoryImpl(AuthRemoteDataSourceImpl(client: http.Client()));

  // List of genres for dropdown
  final List<String> _genres = ['Homme', 'Femme'];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateNaissanceController = TextEditingController();

    // Fetch user data on init
    _loadUserData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _dateNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.userId.isEmpty) {
        throw Exception('Invalid user ID');
      }
      debugPrint('Fetching user with ID: ${widget.userId}');
      
      // Get the user data (JSON map) from the repository
      final userMap = await _authRepository.getUser(widget.userId);
      
      // Convert the map to a User object
      final user = User.fromJson(userMap);

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        // Populate controllers with user data
        _nomController.text = user.nom;
        _prenomController.text = user.prenom;
        _emailController.text = user.email;
        _dateNaissanceController.text = user.date;
        _selectedRegion = user.region;
        _selectedGenre = user.genre ?? 'Homme'; // Default to 'Homme' if null
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading user: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadUserData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new UserModel with updated information.
      final updatedUser = UserModel(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        date: _dateNaissanceController.text,
        region: _selectedRegion ?? '',
        genre: _selectedGenre ?? 'Homme',
        password: _currentUser!.password, // Preserving password
        phone: _currentUser!.phone,
      );

      // Call repository to update the user
      await _authRepository.updateUser(widget.userId, updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de la mise à jour: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

    if (picked != null) {
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
                value: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: 'Région',
                  border: OutlineInputBorder(),
                ),
                items: Regions.list.map((region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRegion = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner votre région';
                  }
                  return null;
                },
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
}
