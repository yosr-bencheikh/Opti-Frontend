import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'dart:ui';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _opticianController = Get.find<OpticianController>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  final Color _primaryColor = Color(0xFF1E5F74);
  final Color _accentColor = Color(0xFF3CAEA3);
  final Color _backgroundColor = Color(0xFFF8F9FA);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isActive = _currentStep >= stepIndex;
    bool isCurrent = _currentStep == stepIndex;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCurrent ? _accentColor : (isActive ? _primaryColor : Colors.grey.shade300),
            shape: BoxShape.circle,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: _accentColor.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ] : null,
          ),
          child: Center(
            child: isCurrent 
              ? Icon(Icons.edit, color: Colors.white, size: 18)
              : (isActive 
                  ? Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isCurrent ? _accentColor : (isActive ? _primaryColor : Colors.grey.shade600),
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixPressed,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: _primaryColor),
          suffixIcon: suffixIcon != null 
            ? IconButton(
                icon: Icon(suffixIcon, color: _primaryColor.withOpacity(0.7)),
                onPressed: onSuffixPressed,
              )
            : null,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: isPrimary ? Colors.white : _primaryColor, backgroundColor: isPrimary ? _primaryColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: _primaryColor),
          ),
          elevation: isPrimary ? 0 : 0,
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : _primaryColor),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildStep1Content() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            'Récupération de compte',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Veuillez entrer l\'adresse email associée à votre compte pour recevoir un code de vérification',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          _buildInputField(
            controller: _emailController,
            label: 'Adresse email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 30),
          Obx(() => _buildButton(
                label: 'Envoyer le code',
                onPressed: () async {
                  if (_emailController.text.isEmpty) {
                    Get.snackbar(
                      'Erreur',
                      'Veuillez entrer votre email',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      margin: EdgeInsets.all(16),
                      borderRadius: 10,
                    );
                    return;
                  }
                  await _opticianController.sendPasswordResetEmail(_emailController.text.trim());
                  setState(() {
                    _currentStep++;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                isLoading: _opticianController.isLoading.value,
              )),
        ],
      ),
    );
  }

  Widget _buildStep2Content() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            'Vérification du code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Entrez le code à 6 chiffres que nous avons envoyé à\n${_emailController.text}',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          _buildInputField(
            controller: _codeController,
            label: 'Code de vérification',
            icon: Icons.lock_outline,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _opticianController.sendPasswordResetEmail(_emailController.text.trim());
                Get.snackbar(
                  'Code envoyé',
                  'Un nouveau code a été envoyé à votre adresse email',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: _accentColor,
                  colorText: Colors.white,
                  margin: EdgeInsets.all(16),
                  borderRadius: 10,
                );
              },
              child: Text(
                'Renvoyer le code',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(height: 20),
          Obx(() => _buildButton(
                label: 'Vérifier le code',
                onPressed: () async {
                  if (_codeController.text.isEmpty) {
                    Get.snackbar(
                      'Erreur',
                      'Veuillez entrer le code de vérification',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      margin: EdgeInsets.all(16),
                      borderRadius: 10,
                    );
                    return;
                  }
                  final verified = await _opticianController.verifyResetCode(
                    _emailController.text.trim(),
                    _codeController.text.trim(),
                  );
                  if (verified) {
                    setState(() {
                      _currentStep++;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  }
                },
                isLoading: _opticianController.isLoading.value,
              )),
          SizedBox(height: 16),
          _buildButton(
            label: 'Retour',
            onPressed: () {
              setState(() {
                _currentStep--;
                _animationController.reset();
                _animationController.forward();
              });
            },
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Content() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            'Nouveau mot de passe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Créez un nouveau mot de passe sécurisé pour votre compte',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          _buildInputField(
            controller: _newPasswordController,
            label: 'Nouveau mot de passe',
            icon: Icons.lock_outline,
            obscureText: _obscureNewPassword,
            suffixIcon: _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
            onSuffixPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          SizedBox(height: 16),
          _buildInputField(
            controller: _confirmPasswordController,
            label: 'Confirmez le mot de passe',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            onSuffixPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          SizedBox(height: 30),
          Obx(() => _buildButton(
                label: 'Réinitialiser le mot de passe',
                onPressed: () async {
                  if (_newPasswordController.text.isEmpty || 
                      _confirmPasswordController.text.isEmpty) {
                    Get.snackbar(
                      'Erreur',
                      'Veuillez remplir tous les champs',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      margin: EdgeInsets.all(16),
                      borderRadius: 10,
                    );
                    return;
                  }
                  if (_newPasswordController.text != _confirmPasswordController.text) {
                    Get.snackbar(
                      'Erreur',
                      'Les mots de passe ne correspondent pas',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      margin: EdgeInsets.all(16),
                      borderRadius: 10,
                    );
                    return;
                  }
                  final success = await _opticianController.resetPassword(
                    _emailController.text.trim(),
                    _codeController.text.trim(),
                    _newPasswordController.text.trim(),
                  );
                  if (success) {
                    Get.offAllNamed('/LoginOpticien');
                  }
                },
                isLoading: _opticianController.isLoading.value,
              )),
          SizedBox(height: 16),
          _buildButton(
            label: 'Retour',
            onPressed: () {
              setState(() {
                _currentStep--;
                _animationController.reset();
                _animationController.forward();
              });
            },
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
                _animationController.reset();
                _animationController.forward();
              });
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          'Récupération de compte',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Step Indicator
                Row(
                  children: [
                    _buildStepIndicator(0, 'Email'),
                    _buildStepConnector(_currentStep > 0),
                    _buildStepIndicator(1, 'Code'),
                    _buildStepConnector(_currentStep > 1),
                    _buildStepIndicator(2, 'Mot de passe'),
                  ],
                ),
                SizedBox(height: 40),
                
                // Step Content
                if (_currentStep == 0)
                  _buildStep1Content()
                else if (_currentStep == 1)
                  _buildStep2Content()
                else
                  _buildStep3Content(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}