import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool _doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  Future<void> signUpUser() async {
    final nom = nameController.text;
    final prenom = prenomController.text;
    final email = emailController.text;
    final date = dateController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (nom.isEmpty || !RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(nom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name')),
      );
      return;
    }

    if (prenom.isEmpty || !RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(prenom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid surname')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (date.isEmpty || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid birthdate')),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Password must contain at least 8 characters, including letters and numbers')),
      );
      return;
    }

    if (!_doPasswordsMatch(password, confirmPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'date': date,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('successfully created')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom"),
              validator: (value) => value == null || value.isEmpty
                  ? "Veuillez entrer votre nom"
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: prenomController,
              decoration: const InputDecoration(labelText: "Prénom"),
              validator: (value) => value == null || value.isEmpty
                  ? "Veuillez entrer votre prénom"
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              validator: (value) => value == null || value.isEmpty
                  ? "Veuillez entrer votre email"
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date de naissance"),
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
                    dateController.text = pickedDate.toString().split(" ")[0];
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              validator: (value) => value == null || value.isEmpty
                  ? "Veuillez entrer un mot de passe"
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Confirmer le mot de passe"),
              validator: (value) => value == null || value.isEmpty
                  ? "Veuillez confirmer le mot de passe"
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUpUser,
              child: const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}
