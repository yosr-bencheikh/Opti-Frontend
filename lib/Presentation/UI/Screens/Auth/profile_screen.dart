import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.currentUser;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                // Fixed null safety for imageUrl access
                backgroundImage: (user?.imageUrl.isNotEmpty == true)
                    ? NetworkImage(user!.imageUrl)
                    : null,
                child: (user?.imageUrl.isNotEmpty != true)
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Welcome ${user?.prenom ?? 'User'}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await controller.pickImage();
                    if (controller.selectedImage != null) {
                      await controller.uploadImage(userId);
                    }
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to upload image: ${e.toString()}',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: const Text('Upload Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.to(() => UpdateProfileScreen(userId: userId)),
                child: const Text('Update Profile'),
              ),
              const SizedBox(height: 20),
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