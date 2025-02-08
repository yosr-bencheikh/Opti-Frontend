import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String userId;
  

  const UpdateProfileScreen({super.key, required this.userId});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthRepositoryImpl _repository;

  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _dateController;
  late TextEditingController _phoneController;

  String? _selectedRegion;
  String? _selectedGenre;

  // List of Regions
  final List<String> _regions = [
    "Tunis",
    "Nabeul",
    "Sousse",
    "Sfax",
    "Gabès",
    "Médenine"
  ];

  @override
  void initState() {
    super.initState();
    _repository = AuthRepositoryImpl(
      AuthRemoteDataSourceImpl(client: http.Client()),
    );
    _initializeControllers();
    _fetchUserData();
  }

  void _initializeControllers() {
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateController = TextEditingController();
    _phoneController = TextEditingController();
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await _repository.getUser(widget.userId);
      _updateControllers(userData);
    } catch (e) {
      _showError("Failed to fetch user data: $e");
    }
  }

  void _updateControllers(User userData) {
    setState(() {
      _nomController.text = userData.name;
      _prenomController.text = userData.prenom;
      _emailController.text = userData.email;
      _dateController.text = userData.date;
      _phoneController.text = userData.phone;
      _selectedRegion = userData.region;
      _selectedGenre = userData.genre;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Create a UserModel object with form data.
      // This ensures the repository check (user is UserModel) passes.
      final updatedUser = UserModel(
        name: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        date: _dateController.text,
        phone: _phoneController.text,
        region: _selectedRegion ?? _regions[0],
        genre: _selectedGenre ?? 'Homme',
        password: '', // Not updating password here
      );

      // Pass the UserModel object directly to the updateUser method.
      await _repository.updateUser(widget.userId, updatedUser);
      _showSuccess("Profile updated successfully!");
    } catch (e) {
      _showError("Failed to update profile: $e");
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le Profil"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: "Nom",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? "Veuillez entrer votre nom" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: "Prénom",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? "Veuillez entrer votre prénom"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Veuillez entrer votre email";
                  }
                  if (!value!.contains("@")) {
                    return "Email invalide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? "Veuillez entrer votre téléphone"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: "Date de Naissance",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateController.text =
                              pickedDate.toString().split(" ")[0];
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                validator: (value) => value?.isEmpty ?? true
                    ? "Veuillez entrer votre date de naissance"
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: "Région",
                  border: OutlineInputBorder(),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRegion = value),
                validator: (value) =>
                    value == null ? "Sélectionnez une région" : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Genre",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Homme"),
                      value: "Homme",
                      groupValue: _selectedGenre,
                      onChanged: (value) =>
                          setState(() => _selectedGenre = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Femme"),
                      value: "Femme",
                      groupValue: _selectedGenre,
                      onChanged: (value) =>
                          setState(() => _selectedGenre = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Enregistrer",
                  style: TextStyle(fontSize: 16),
                ),
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
    _dateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
