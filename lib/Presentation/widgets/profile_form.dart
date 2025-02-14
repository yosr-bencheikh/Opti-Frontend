import 'package:flutter/material.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/core/constants/regions.dart';

class ProfileForm extends StatelessWidget {
  final User user;
  final Function(User) onSave;

  const ProfileForm({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: user.nom);
    final prenomController = TextEditingController(text: user.prenom);
    final emailController = TextEditingController(text: user.email);
    final dateNaissanceController =
        TextEditingController(text: user.date.toString().split(' ')[0]);
    String selectedRegion = user.region;
    String selectedGenre = user.genre;
    DateTime userDate = DateTime.parse(user.date);

    return Form(
      key: formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: nomController,
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
            validator: (value) =>
                value == null || value.isEmpty || !value.contains("@")
                    ? "Veuillez entrer un email valide"
                    : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: dateNaissanceController,
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
                dateNaissanceController.text =
                    pickedDate.toString().split(" ")[0];
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRegion,
            decoration: const InputDecoration(labelText: "Région"),
            items: Regions.list.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              selectedRegion = value ?? selectedRegion;
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
                  groupValue: selectedGenre,
                  onChanged: (value) {
                    selectedGenre = value ?? selectedGenre;
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("Femme"),
                  value: "Femme",
                  groupValue: selectedGenre,
                  onChanged: (value) {
                    selectedGenre = value ?? selectedGenre;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                try {
                  // Convert the date string into a DateTime object
                  String selectedDate = dateNaissanceController.text;

                  // Create a new User with the updated data
                  onSave(User(
                    email: emailController.text,
                    nom: nomController.text,
                    prenom: prenomController.text,
                    date: selectedDate, // Pass the DateTime object
                    region: selectedRegion,
                    genre: selectedGenre,
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
