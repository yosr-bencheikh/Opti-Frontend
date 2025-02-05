import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen2 extends StatefulWidget {
  final String nom;
  final String prenom;
  final String email;
  final String date;
  final String password;

  const SignUpScreen2({
    Key? key,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.date,
    required this.password,
  }) : super(key: key);

  @override
  _SignUpScreen2State createState() => _SignUpScreen2State();
}

class _SignUpScreen2State extends State<SignUpScreen2> {
  final phoneController = TextEditingController();
  final regionController = TextEditingController();
  final genderController = TextEditingController();

  Future<void> signUpUser() async {
    final phone = phoneController.text;
    final region = regionController.text;
    final gender = genderController.text;

    // Validation des champs
    if (phone.isEmpty || region.isEmpty || gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les champs doivent être remplis')),
      );
      return;
    }

    // Envoi des données au serveur
    final url = Uri.parse('http://localhost:3000/api/users'); // Remplacez l'URL par celle de votre backend
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nom': widget.nom,
        'prenom': widget.prenom,
        'email': widget.email,
        'date': widget.date,
        'password': widget.password,
        'phone': phone,
        'region': region,
        'gender': gender,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );
      // Naviguer vers une autre page si nécessaire
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'inscription')),
      );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Champ Numéro de téléphone avec icône
            TextField(
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
            ),
            const SizedBox(height: 15),

            // Champ Région avec icône
            TextField(
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
            ),
            const SizedBox(height: 15),

            // Champ Sexe avec icône
            TextField(
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
    );
  }
}
