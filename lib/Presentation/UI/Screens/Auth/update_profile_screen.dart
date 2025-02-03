import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateProfileScreen extends StatefulWidget {
  final String userId;

  const UpdateProfileScreen({super.key, required this.userId});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _dateNaissanceController;

  // Dropdown & Radio Selection
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

  // Fetch user data from the backend
  Future<void> _fetchUserData(String userId) async {
    final url = Uri.parse('http://localhost:3000/api/users/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);

      // Populate the controllers with the data received
      setState(() {
        _nomController.text = userData['name'] ?? '';
        _prenomController.text = userData['prenom'] ??
            ''; // Assuming 'prenom' exists in the response
        _emailController.text = userData['email'] ?? '';
        _dateNaissanceController.text = userData['dateNaissance'] ?? '';
        _selectedRegion = userData['region'] ??
            _regions[0]; // Default to first region if no region is provided
        _selectedGenre = userData['genre'] ??
            'Homme'; // Default to 'Homme' if no genre is provided
      });
    } else {
      // Handle error if data retrieval fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers (start with empty or default text)
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateNaissanceController = TextEditingController();

    // Fetch the user data when the screen is loaded
    _fetchUserData(widget.userId);
  }

  // Update Profile function
  Future<void> _updateProfile(String userId) async {
    final url = Uri.parse('http://localhost:3000/api/users/$userId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'dateNaissance': _dateNaissanceController.text,
        'region': _selectedRegion,
        'genre': _selectedGenre,
      }),
    );

    // Check if the status code is 200 (success)
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
    } else {
      // If the status code is not 200, show the exact error from the response body
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nom
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: "Nom",
                  hintText: _nomController.text.isEmpty
                      ? 'Entrez votre nom'
                      : _nomController.text,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer votre nom";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Prénom
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: "Prénom",
                  hintText: _prenomController.text.isEmpty
                      ? 'Entrez votre prénom'
                      : _prenomController.text,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer votre prénom";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: _emailController.text.isEmpty
                      ? 'Entrez votre email'
                      : _emailController.text,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains("@")) {
                    return "Veuillez entrer un email valide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Date de Naissance
              TextFormField(
                controller: _dateNaissanceController,
                decoration: InputDecoration(
                  labelText: "Date de Naissance",
                  hintText: _dateNaissanceController.text.isEmpty
                      ? 'Entrez votre date de naissance'
                      : _dateNaissanceController.text,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _dateNaissanceController.text =
                              pickedDate.toString().split(" ")[0];
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),

              // Région
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: const InputDecoration(labelText: "Région"),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Sélectionnez une région" : null,
              ),
              const SizedBox(height: 10),

              // Genre
              const Text("Genre",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Homme"),
                      value: "Homme",
                      groupValue: _selectedGenre,
                      onChanged: (value) {
                        setState(() {
                          _selectedGenre = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Femme"),
                      value: "Femme",
                      groupValue: _selectedGenre,
                      onChanged: (value) {
                        setState(() {
                          _selectedGenre = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateProfile(widget.userId);
                  }
                },
                child: const Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
