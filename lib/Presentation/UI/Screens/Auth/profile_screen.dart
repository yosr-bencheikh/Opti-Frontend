import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userEmail =
        (Get.arguments is String) ? Get.arguments as String : 'Unknown User';

    // Call loadUserData when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentUser == null) {
        final userEmail = Get.find<SharedPreferences>().getString('userEmail');
        if (userEmail != null && userEmail.isNotEmpty) {
          controller.loadUserData(userEmail);
        }
      }
    });

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

        // Add null check and loading state
        if (user == null) {
          return const Center(child: Text('Loading user data...'));
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.imageUrl.isNotEmpty
                      ? NetworkImage(user.imageUrl)
                      : null,
                  child: user.imageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text('Welcome ${user.prenom}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                // Display user information with better formatting
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Nom', user.nom),
                        _buildInfoRow('Prénom', user.prenom),
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('Date de Naissance', user.date),
                        _buildInfoRow('Phone', user.phone),
                        _buildInfoRow('Region', user.region),
                        _buildInfoRow('Gender', user.genre),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await controller.pickImage();
                      if (controller.selectedImage != null) {
                        await controller
                            .uploadImage(user.email); // Pass the email here
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
                  onPressed: () {
                    if (user.email.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Email is required to update the profile.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      // In the profile screen, check the email passed to the update screen
                      debugPrint(
                          'Navigating to UpdateProfileScreen with email: ${user.email}');

                      Get.to(() => UpdateProfileScreen(email: user.email));
                    }
                  },
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
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value.isEmpty ? 'N/A' : value),
        ],
      ),
    );
  }
}
