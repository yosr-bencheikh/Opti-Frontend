import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreenOpticien extends StatefulWidget {
  const LoginScreenOpticien({Key? key}) : super(key: key);

  @override
  State<LoginScreenOpticien> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenOpticien> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  final OpticianController _opticianController = Get.put(OpticianController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E5F74), // Bleu professionnel
              Color(0xFF133B5C), // Bleu foncé
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left side - Login form
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1E5F74),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'OptiVision Pro',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E5F74),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E5F74),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Veuillez vous connecter pour accéder à votre espace professionnel',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Email Field
                            Text(
                              'Adresse e-mail',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                              
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF1E5F74),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF1E5F74),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Password Field
                            Text(
                              'Mot de passe',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF1E5F74),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF1E5F74),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Remember me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: true,
                                      activeColor: Color(0xFF1E5F74),
                                      onChanged: (value) {
                                        // TODO: Implement remember me
                                      },
                                    ),
                                    Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(
                                      color: Color(0xFF1E5F74),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            
                            // Login Button
                            SizedBox(
  width: double.infinity,
  height: 50,
  child: Obx(() => _opticianController.isLoading.value
    ? Center(child: CircularProgressIndicator(color: Colors.white))
    : ElevatedButton(
        onPressed: () async {
          final email = _emailController.text.trim();
          final password = _passwordController.text.trim();

          if (email.isEmpty || password.isEmpty) {
            Get.snackbar(
              'Erreur',
              'Veuillez remplir tous les champs',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          await _opticianController.loginWithEmail(email, password);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1E5F74),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Se connecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
  ),
),
                          ],
                        ),
                      ),
                    ),
                    
                    // Right side - Background with text and illustration
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E5F74), // Bleu professionnel
                              Color(0xFF133B5C), // Bleu foncé
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.visibility,
                                    color: Color(0xFF1E5F74),
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                "L'excellence optique à portée de clic",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: 80,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Gérez vos clients, inventaires et rendez-vous depuis une seule plateforme professionnelle conçue pour les opticiens.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              // Custom illustration placeholder
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Stylized glasses illustration placeholder
                                    Container(
                                      width: 160,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
