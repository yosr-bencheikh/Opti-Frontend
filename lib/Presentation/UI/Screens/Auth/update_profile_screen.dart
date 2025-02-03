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
        _nomController.text = userData['nom'] ?? '';
        _prenomController.text = userData['prenom'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _dateNaissanceController.text = userData['dateNaissance'] ?? '';
        _selectedRegion = userData['region'] ?? _regions[0];
        _selectedGenre = userData['genre'] ?? 'Homme';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateNaissanceController = TextEditingController();

    _fetchUserData(widget.userId);
  }

  // Update Profile function
  Future<void> _updateProfile(String userId) async {
    final url = Uri.parse('http://localhost:3000/api/users/$userId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'dateNaissance': _dateNaissanceController.text,
        'region': _selectedRegion,
        'genre': _selectedGenre,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
    } else {
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
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (value) => value == null || value.isEmpty
                    ? "Veuillez entrer votre nom"
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: "Prénom"),
                validator: (value) => value == null || value.isEmpty
                    ? "Veuillez entrer votre prénom"
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value == null || value.isEmpty || !value.contains("@")
                        ? "Veuillez entrer un email valide"
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateNaissanceController,
                decoration:
                    const InputDecoration(labelText: "Date de Naissance"),
                readOnly: true,
                onTap: () async {
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
              const SizedBox(height: 10),
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
              const Text("Genre", style: TextStyle(fontSize: 16)),
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
