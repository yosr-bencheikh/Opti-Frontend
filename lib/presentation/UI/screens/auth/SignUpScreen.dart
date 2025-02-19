import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/Presentation/utils/validators.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  final regionController = TextEditingController();
  final genreController = TextEditingController();
  final phoneController = TextEditingController();

  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

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

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        dateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/b1.jpeg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SingleChildScrollView(
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
                        const SizedBox(height: 20),
                        _buildTextField(
                            nameController,
                            "Nom",
                            "Entrez votre nom",
                            Icons.person,
                            Validators.isValidName),
                        _buildTextField(
                            prenomController,
                            "Prénom",
                            "Entrez votre prénom",
                            Icons.person_outline,
                            Validators.isValidPrenom),
                        _buildTextField(
                            emailController,
                            "Email",
                            "Entrez votre email",
                            Icons.email,
                            Validators.isValidEmail),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                                dateController,
                                "Date de naissance",
                                "YYYY-MM-DD",
                                Icons.calendar_today,
                                Validators.isValidDate),
                          ),
                        ),
                        _buildPasswordField(
                          controller: passwordController,
                          hintText: 'Mot de passe',
                        ),
                        _buildPasswordField(
                          controller: confirmPasswordController,
                          hintText: 'Confirmer le mot de passe',
                          obscureText: true,
                        ),
                        _buildDropdownField(regionController, "Région",
                            Icons.location_on, Regions.list),
                        _buildDropdownField(genreController, "Genre",
                            Icons.transgender, ['Homme', 'Femme']),
                        _buildTextField(
                            phoneController,
                            "Numéro de téléphone",
                            "Entrez votre numéro de téléphone",
                            Icons.phone,
                            Validators.isValidPhone),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:
                              _authController.isLoading.value ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15)),
                          child: const Text("Inscription"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_authController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          )),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon, String? Function(String?)? validator,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(TextEditingController controller, String label,
      IconData icon, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        onChanged: (value) => setState(() => controller.text = value!),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        validator: (value) => value == null || value.isEmpty
            ? 'Veuillez sélectionner une option'
            : null,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: hintText,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() {
              obscureText = !obscureText;
            }),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: Validators.isValidPassword,
      ),
    );
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      User newUser = User(
        nom: nameController.text,
        prenom: prenomController.text,
        email: emailController.text,
        date: dateController.text,
        password: passwordController.text,
        region: regionController.text,
        genre: genreController.text,
        phone: phoneController.text,
      );
      await _authController.signUp(newUser);
    }
  }

  // Modify the confirm password field
}
