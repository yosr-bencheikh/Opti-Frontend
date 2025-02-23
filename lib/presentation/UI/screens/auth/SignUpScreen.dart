import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/Presentation/utils/validators.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/core/styles/text_styles.dart';
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
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "Créez votre compte",
                          style: AppTextStyles.loginTitleStyle.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Remplissez les champs ci-dessous pour vous inscrire.",
                          style: AppTextStyles.loginSubtitleStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
                        _buildStyledTextField(
                          controller: nameController,
                          label: "Nom",
                          hint: "Entrez votre nom",
                          icon: Icons.person,
                          validator: Validators.isValidName,
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          controller: prenomController,
                          label: "Prénom",
                          hint: "Entrez votre prénom",
                          icon: Icons.person_outline,
                          validator: Validators.isValidPrenom,
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
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
                            child: _buildStyledTextField(
                              controller: dateController,
                              label: "Date de naissance",
                              hint: "YYYY-MM-DD",
                              icon: Icons.calendar_today,
                              validator: Validators.isValidDate,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          controller: passwordController,
                          label: "Mot de passe",
                          hint: "Entrez votre mot de passe",
                          obscureText: true,
                          icon: Icons.lock,
                          validator: Validators.isValidPassword,
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          controller: confirmPasswordController,
                          label: "Confirmer le mot de passe",
                          hint: "Confirmez votre mot de passe",
                          obscureText: true,
                          icon: Icons.lock_outline,
                          validator: (value) =>
                              Validators.isValidConfirmPassword(
                                  value, passwordController.text),
                        ),
                        const SizedBox(height: 10),

                        // Styled Dropdowns
                        _buildStyledDropdown(
                          value: regionController.text,
                          label: 'Région',
                          icon: Icons.location_on,
                          items: Regions.list,
                          onChanged: (value) {
                            setState(() {
                              regionController.text = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner une région';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildStyledDropdown(
                          value: genreController.text,
                          label: 'Genre',
                          icon: Icons.transgender,
                          items: ['Homme', 'Femme'],
                          onChanged: (value) {
                            setState(() {
                              genreController.text = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner votre genre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildStyledTextField(
                          controller: phoneController,
                          label: "Numéro de téléphone",
                          hint: "Entrez votre numéro de téléphone",
                          icon: Icons.phone,
                          validator: Validators.isValidPhone,
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        Container(
                          decoration: AppDecorations.buttonDecoration,
                          child: ElevatedButton(
                            onPressed: _authController.isLoading.value
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      List<String> dateParts =
                                          dateController.text.split('-');
                                      if (dateParts.length == 3) {
                                        String formattedDate =
                                            "${dateParts[0]}-${dateParts[1]}-${dateParts[2]}";
                                        User newUser = User(
                                          nom: nameController.text,
                                          prenom: prenomController.text,
                                          email: emailController.text,
                                          date: formattedDate,
                                          password: passwordController.text,
                                          region: regionController.text,
                                          genre: genreController.text,
                                          phone: phoneController.text,
                                        );
                                        await _authController.signUp(newUser);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Inscription",
                              style: AppTextStyles.buttonTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_authController.isLoading.value)
                Container(
                  color: AppColors.blackColor.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
            ],
          )),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppDecorations.inputDecoration,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryColor,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppDecorations.inputDecoration,
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryColor,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        validator: validator,
      ),
    );
  }
}
