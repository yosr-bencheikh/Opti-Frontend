import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';

class SignUpScreen2 extends StatefulWidget {
  final User user;

  const SignUpScreen2({Key? key, required this.user}) : super(key: key);

  @override
  _SignUpScreen2State createState() => _SignUpScreen2State();
}

class _SignUpScreen2State extends State<SignUpScreen2> {
  final phoneController = TextEditingController();
  final regionController = TextEditingController();
  final genderController = TextEditingController();
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>(); // Add a form key for validation

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl(
      AuthRemoteDataSourceImpl(client: http.Client()), // Pass as a positional argument
    );
  }

  Future<void> signUpUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedUser = User(
          nom: widget.user.nom,
          prenom: widget.user.prenom,
          email: widget.user.email,
          date: widget.user.date,
          password: widget.user.password,
          phone: phoneController.text,
          region: regionController.text,
          gender: genderController.text,
        );

        await _authRepository.signUp(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'inscription: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compléter l'inscription"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Champ Numéro de téléphone avec icône
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  } else if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                    return 'Le numéro de téléphone doit comporter 8 chiffres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Champ Région avec icône
              TextFormField(
                controller: regionController,
                decoration: InputDecoration(
                  labelText: 'Région',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre région';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Champ Sexe avec icône
              TextFormField(
                controller: genderController,
                decoration: InputDecoration(
                  labelText: 'Sexe',
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre sexe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Bouton d'inscription
              ElevatedButton(
                onPressed: signUpUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'S\'inscrire',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}