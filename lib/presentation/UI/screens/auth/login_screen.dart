import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_api.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:http/http.dart' as http;

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
      image: AssetImage('assets/images/b2.jpeg'), // Chemin de ton image
      fit: BoxFit.cover,
      ),),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                // Logo et branding
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: 70,
                    color: const Color.fromARGB(255, 108, 97, 192),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'VISION EXCELLENCE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: const Color.fromARGB(255, 108, 97, 192),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'CENTRE D\'OPTOMÉTRIE',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: const Color.fromARGB(255, 108, 97, 192),
                  ),
                ),
                SizedBox(height: 48),
                // Carte principale
                Card(
                  elevation: 20,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  color: Colors.white.withOpacity(0.4),
                  child: Container(
                    padding: EdgeInsets.all(32),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2647),
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Accédez à votre espace personnel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 40),
                        // Champs de saisie stylisés
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
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
                                color: Color(0xFF0A2647),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Color(0xFF0A2647),
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
                                  color: Color(0xFF0A2647),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
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
                                color: Color(0xFF0A2647),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Color(0xFF0A2647),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Color(0xFF0A2647),
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
                                  color: Color(0xFF0A2647),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),
                        // Bouton de connexion avec animation
                        Obx(() => Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A2647),
                                Color(0xFF205295),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF0A2647).withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                authController.isLoading.value ? null : loginUser,
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
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'SE CONNECTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        )),
                        SizedBox(height: 24),
                        // Options supplémentaires
                        Center(
                          child: TextButton(
                            onPressed: () => Get.toNamed('/ForgotPasswordScreen'),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: Color(0xFF0A2647),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),
                        // Séparateur élégant
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
                              child: Text(
                                'Ou continuer avec',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
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
                        // Boutons sociaux modernisés
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
                                    size: 24, color: Color(0xFF0A2647)),
                                label: Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Color(0xFF0A2647),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
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
                                    size: 24, color: Color(0xFF0A2647)),
                                label: Text(
                                  'Facebook',
                                  style: TextStyle(
                                    color: Color(0xFF0A2647),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
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
                        // Lien d'inscription élégant
                        Center(
                          child: TextButton(
                            onPressed: () => Get.toNamed('/signup'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Nouveau patient ? ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  TextSpan(
                                    text: 'Créer un compte',
                                    style: TextStyle(
                                      color: Color(0xFF0A2647),
                                      fontWeight: FontWeight.bold,
                                    ),
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
