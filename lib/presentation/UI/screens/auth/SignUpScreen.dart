import 'package:flutter/material.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/profile_screen.dart';
import 'package:opti_app/Presentation/utils/validators.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
import 'package:http/http.dart' as http;
// Make sure to import your ProfileScreen (adjust the path as needed)

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final dateController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // New controllers
  final regionController = TextEditingController();
  final genreController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl(
    AuthRemoteDataSourceImpl(client: http.Client()),
  );

  @override
  void dispose() {
    nameController.dispose();
    prenomController.dispose();
    emailController.dispose();
    dateController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    regionController.dispose();
    genreController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  /// This method shows a date picker and formats the selected date as "YYYY-MM-DD"
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        // Format the date as "YYYY-MM-DD"
        dateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inscription",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Créez votre compte",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Remplissez les champs ci-dessous pour vous inscrire.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
            _buildTextField(
  controller: nameController,
  label: "Nom",
  hint: "Entrez votre nom",
  icon: Icons.person,
  validator: Validators.isValidName,
),

const SizedBox(height: 10),
_buildTextField(
  controller: prenomController,
  label: "Prénom",
  hint: "Entrez votre prénom",
  icon: Icons.person_outline,
  validator: Validators.isValidPrenom,
),
              const SizedBox(height: 10),
                  _buildTextField(
                  controller: emailController,
                  label: "Email",
                  hint: "Entrez votre email",
                  icon: Icons.email,
                  validator: Validators.isValidEmail,
                ),             
                 const SizedBox(height: 10),
              GestureDetector(
  onTap: _selectDate,
  child: AbsorbPointer(
    child: _buildTextField(
      controller: dateController,
      label: "Date de naissance",
      hint: "YYYY-MM-DD",
      icon: Icons.calendar_today,
      validator: Validators.isValidDate,
    ),
  ),
),
                const SizedBox(height: 10),
                _buildTextField(
  controller: passwordController,
  label: "Mot de passe",
  hint: "Entrez votre mot de passe",
  obscureText: true,
  icon: Icons.lock,
  validator: Validators.isValidPassword,
),
                const SizedBox(height: 10),
              _buildTextField(
  controller: confirmPasswordController,
  label: "Confirmer le mot de passe",
  hint: "Confirmez votre mot de passe",
  obscureText: true,
  icon: Icons.lock_outline,
  validator: (value) => Validators.isValidConfirmPassword(value, passwordController.text),
),
                const SizedBox(height: 10),
                          _buildTextField(
              controller: regionController,
              label: "Région",
              hint: "Entrez votre région",
              icon: Icons.location_on,
              validator: Validators.isValidRegion,
            ),  
                const SizedBox(height: 10),
              _buildTextField(
  controller: genreController,
  label: "Genre",
  hint: "Entrez votre genre",
  icon: Icons.transgender,
  validator: Validators.isValidGenre,
),
                const SizedBox(height: 10),
              _buildTextField(
  controller: phoneController,
  label: "Numéro de téléphone",
  hint: "Entrez votre numéro de téléphone",
  icon: Icons.phone,
  validator: Validators.isValidPhone,
),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // The date is already in the "YYYY-MM-DD" format
                        List<String> dateParts = dateController.text.split('-');
                        if (dateParts.length == 3) {
                          String formattedDate =
                              "${dateParts[0]}-${dateParts[1]}-${dateParts[2]}";

                          // Create User object with the correctly formatted date
                          User newUser = User(
                            name: nameController.text,
                            prenom: prenomController.text,
                            email: emailController.text,
                            date: formattedDate,
                            password: passwordController.text,
                            region: regionController.text,
                            genre: genreController.text,
                            phone: phoneController.text,
                          );

                          await _authRepository.signUp(newUser);

                          // Show a success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Inscription réussie!")),
                          );

                          // Navigate to ProfileScreen (replace the current page)
                          Navigator.pushReplacementNamed(
                            context,
                            '/profileScreen',
                          );
                        } else {
                          throw FormatException("Invalid date format");
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Format de date invalide")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  bool obscureText = false,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    validator: validator,
  );
}

}
