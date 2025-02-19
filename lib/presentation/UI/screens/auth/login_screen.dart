import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_api.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:http/http.dart' as http;
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _obscurePassword = true;

  // Get the AuthController instance
  final AuthController authController = Get.find<AuthController>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  Future<void> loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
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
          image: DecorationImage(
            image: AssetImage('assets/images/b2.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Logo and branding
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.whiteColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.visibility,
                      size: 70,
                      color: AppColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text('VISION EXCELLENCE', style: AppTextStyles.titleStyle),
                  SizedBox(height: 8),
                  Text('CENTRE D\'OPTOMÉTRIE', style: AppTextStyles.subtitleStyle),
                  SizedBox(height: 48),
                  
                  // Main Card
                  Card(
                    elevation: 20,
                    shadowColor: AppColors.blackColor.withOpacity(0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    color: AppColors.whiteColor.withOpacity(0.4),
                    child: Container(
                      padding: EdgeInsets.all(32),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connexion', style: AppTextStyles.loginTitleStyle),
                          SizedBox(height: 8),
                          Text('Accédez à votre espace personnel', 
                               style: AppTextStyles.loginSubtitleStyle),
                          SizedBox(height: 40),
                          
                          // Email Field
                          Container(
                            decoration: AppDecorations.inputDecoration,
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
                            decoration: AppDecorations.inputDecoration,
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
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
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
                            decoration: AppDecorations.buttonDecoration,
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
                              onPressed: () => Get.toNamed('/ForgotPasswordScreen'),
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
                                    var result = Get.find<AuthController>()
                                        .loginWithGoogle();
                                    if (result != null) {
                                      print("Connexion Google réussie!");
                                    }
                                  },
                                  icon: Icon(Icons.g_mobiledata,
                                      size: 24, color: AppColors.primaryColor),
                                  label: Text('Google',
                                      style: AppTextStyles.socialButtonTextStyle),
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
                                    var user = Get.find<AuthController>()
                                        .loginWithFacebook();
                                    if (user != null) {
                                      print("Connexion Facebook réussie!");
                                    }
                                  },
                                  icon: Icon(Icons.facebook,
                                      size: 24, color: AppColors.primaryColor),
                                  label: Text('Facebook',
                                      style: AppTextStyles.socialButtonTextStyle),
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
                                      text: 'Nouveau patient ? ',
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