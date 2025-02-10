import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupérer l'instance existante du contrôleur

    final String userId = Get.arguments ?? 'Unknown User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/'),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.currentUser.value == null) {
          return Center(child: Text('No user data found.'));
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome ${controller.currentUser.value?.prenom}'),
              ElevatedButton(
                onPressed: () =>
                    Get.to(() => UpdateProfileScreen(userId: userId)),
                child: const Text('Update Profile'),
              ),
              ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
