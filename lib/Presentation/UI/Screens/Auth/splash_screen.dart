// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: FutureBuilder<bool>(
        future: authController.autoLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            Future.microtask(() => Get.offAllNamed('/login'));
            return const SizedBox.shrink();
          }

          if (snapshot.data == true) {
            Future.microtask(() => Get.offAllNamed('/profileScreen',
                arguments: authController.currentUser?.email));
          } else {
            Future.microtask(() => Get.offAllNamed('/login'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
