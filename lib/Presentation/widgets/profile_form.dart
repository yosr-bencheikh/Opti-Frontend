import 'package:flutter/material.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/core/constants/regions.dart';

class ProfileForm extends StatelessWidget {
  final User user;
  final Function(User) onSave;

  const ProfileForm({
    Key? key,
    required this.user,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nomController = TextEditingController(text: user.nom);
    final _prenomController = TextEditingController(text: user.prenom);
    final _emailController = TextEditingController(text: user.email);
    final _dateNaissanceController =
        TextEditingController(text: user.date.toString().split(' ')[0]);
    String _selectedRegion = user.region;
    String _selectedGenre = user.genre;
    DateTime userDate = DateTime.parse(user.date);

    return Form(
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
            decoration: const InputDecoration(labelText: "Date de Naissance"),
            readOnly: true,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: userDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                _dateNaissanceController.text =
                    pickedDate.toString().split(" ")[0];
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: const InputDecoration(labelText: "Région"),
            items: Regions.list.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              _selectedRegion = value ?? _selectedRegion;
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
                    _selectedGenre = value ?? _selectedGenre;
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("Femme"),
                  value: "Femme",
                  groupValue: _selectedGenre,
                  onChanged: (value) {
                    _selectedGenre = value ?? _selectedGenre;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                try {
                  // Convert the date string into a DateTime object
                  String selectedDate = _dateNaissanceController.text;

                  // Create a new User with the updated data
                  onSave(User(
                    email: _emailController.text,
                    nom: _nomController.text,
                    prenom: _prenomController.text,
                    date: selectedDate, // Pass the DateTime object
                    region: _selectedRegion,
                    genre: _selectedGenre,
                    password: '',
                    phone: '',
                  ));
                } catch (e) {
                  // Handle error if the date format is incorrect
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Format de date invalide")),
                  );
                }
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}
