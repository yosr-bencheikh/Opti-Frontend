import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/core/styles/text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Get the AuthController instance
  final AuthController authController = Get.find<AuthController>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  Future<void> loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Remplissez tous les champs',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await authController.loginWithEmail(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              AppColors.whiteColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Main Card
                  Card(
                    elevation: 10,
                    shadowColor: const Color.fromARGB(255, 97, 115, 205)
                        .withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    color: AppColors.whiteColor,
                    child: Container(
                      padding: EdgeInsets.all(32),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connexion',
                              style: AppTextStyles.loginTitleStyle),
                          SizedBox(height: 8),
                          Text('Accédez à votre espace personnel',
                              style: AppTextStyles.loginSubtitleStyle),
                          SizedBox(height: 40),

                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Adresse email',
                                labelStyle: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
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
                            ),
                          ),
                          SizedBox(height: 24),

                          // Password Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.primaryColor,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
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
                            ),
                          ),
                          SizedBox(height: 32),

                          // Login Button
                          Obx(() => Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.secondaryColor,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authController.isLoading.value
                                      ? null
                                      : loginUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: authController.isLoading.value
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.whiteColor,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('SE CONNECTER',
                                          style: AppTextStyles.buttonTextStyle),
                                ),
                              )),
                          SizedBox(height: 24),

                          // Forgot Password
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  Get.toNamed('/ForgotPasswordScreen'),
                              child: Text('Mot de passe oublié ?',
                                  style: AppTextStyles.forgotPasswordStyle),
                            ),
                          ),
                          SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey[300]!,
                                        Colors.grey[300]!,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Ou continuer avec',
                                    style: AppTextStyles.loginSubtitleStyle),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey[300]!,
                                        Colors.grey[300]!,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),

                          // Social Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Get.find<AuthController>()
                                        .loginWithGoogle();
                                    print("Connexion Google réussie!");
                                                                    },
                                  icon: Icon(Icons.g_mobiledata,
                                      size: 24, color: AppColors.primaryColor),
                                  label: Text('Google',
                                      style:
                                          AppTextStyles.socialButtonTextStyle),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.whiteColor,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Get.find<AuthController>()
                                        .loginWithFacebook();
                                    print("Connexion Facebook réussie!");
                                                                    },
                                  icon: Icon(Icons.facebook,
                                      size: 24, color: AppColors.primaryColor),
                                  label: Text('Facebook',
                                      style:
                                          AppTextStyles.socialButtonTextStyle),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.whiteColor,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),

                          // Sign Up Link
                          Center(
                            child: TextButton(
                              onPressed: () => Get.toNamed('/signup'),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Nouveau utilisateur ? ',
                                      style: AppTextStyles.signUpTextStyle,
                                    ),
                                    TextSpan(
                                      text: 'Créer un compte',
                                      style: AppTextStyles.signUpLinkStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
