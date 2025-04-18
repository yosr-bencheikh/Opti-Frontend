import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/core/styles/text_styles.dart';
import 'package:opti_app/Presentation/utils/validators.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String email;

  const UpdateProfileScreen({super.key, required this.email});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _dateNaissanceController;
  late TextEditingController _phoneController;

  String _selectedRegion = '';
  String _selectedGenre = 'Homme';
  bool _isLoading = false;
  User? _currentUser;

  final AuthController _authController = Get.find<AuthController>();
  final List<String> _genres = ['Homme', 'Femme'];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _dateNaissanceController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.email.isEmpty) {
        Get.snackbar('Erreur', 'L\'email est requis',
            snackPosition: SnackPosition.BOTTOM);
        Get.back();
      } else {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      User? user = _authController.currentUser;
      if (user == null) {
        await _authController.loadUserData(widget.email);
        user = _authController.currentUser;
      }

      if (user == null) throw Exception('Utilisateur non trouvé');

      // Format the date to show only YYYY-MM-DD
      String formattedDate;
      try {
        // Try parsing the date first
        DateTime? parsedDate = DateTime.tryParse(user.date);
        if (parsedDate != null) {
          formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
        } else {
          // Fallback to splitting if parsing fails
          formattedDate = user.date.split(' ')[0];
        }
      } catch (e) {
        // If any error occurs, use the raw value
        formattedDate = user.date;
      }

      setState(() {
        _currentUser = user;
        _nomController.text = user!.nom;
        _prenomController.text = user.prenom;
        _emailController.text = user.email;
        _dateNaissanceController.text = formattedDate;
        _selectedRegion = user.region;
        _phoneController.text = user.phone;
        _selectedGenre = user.genre.isNotEmpty ? user.genre : 'Homme';
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données utilisateur.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = UserModel(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        date: _dateNaissanceController.text,
        region: _selectedRegion,
        genre: _selectedGenre,
        phone: _phoneController.text,
        password: _currentUser!.password,
      );

      await _authController.updateUserProfile(widget.email, updatedUser);

      Get.snackbar('Succès', 'Profil mis à jour avec succès',
          snackPosition: SnackPosition.BOTTOM);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de la mise à jour du profil.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateNaissanceController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _dateNaissanceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.inputDecoration,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
      margin: const EdgeInsets.only(bottom: 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le profil"),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Mettre à jour votre profil",
                    style: AppTextStyles.loginTitleStyle.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Modifiez les champs que vous souhaitez mettre à jour.",
                    style: AppTextStyles.loginSubtitleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  _buildStyledTextField(
                    controller: _nomController,
                    label: "Nom",
                    hint: "Entrez votre nom",
                    icon: Icons.person,
                    validator: Validators.isValidName,
                  ),
                  _buildStyledTextField(
                    controller: _prenomController,
                    label: "Prénom",
                    hint: "Entrez votre prénom",
                    icon: Icons.person_outline,
                    validator: Validators.isValidPrenom,
                  ),
                  _buildStyledTextField(
                    controller: _emailController,
                    label: "Email",
                    hint: "Entrez votre email",
                    icon: Icons.email,
                    validator: Validators.isValidEmail,
                  ),
                  _buildStyledTextField(
                    controller: _phoneController,
                    label: "Téléphone",
                    hint: "Entrez votre numéro de téléphone",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.isValidPhone,
                  ),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: _buildStyledTextField(
                        controller: _dateNaissanceController,
                        label: "Date de naissance",
                        hint: "YYYY-MM-DD",
                        icon: Icons.calendar_today,
                        readOnly: true,
                        validator: Validators.isValidDate,
                      ),
                    ),
                  ),
                  _buildStyledDropdown(
                    value: _selectedRegion,
                    label: 'Région',
                    icon: Icons.location_on,
                    items: Regions.list,
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une région';
                      }
                      return null;
                    },
                  ),
                  _buildStyledDropdown(
                    value: _selectedGenre,
                    label: 'Genre',
                    icon: Icons.transgender,
                    items: _genres,
                    onChanged: (value) {
                      setState(() {
                        _selectedGenre = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner votre genre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Update Button
                  Container(
                    decoration: AppDecorations.buttonDecoration,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Mettre à jour",
                        style: AppTextStyles.buttonTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading && _currentUser == null)
            Container(
              color: AppColors.blackColor.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.whiteColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
