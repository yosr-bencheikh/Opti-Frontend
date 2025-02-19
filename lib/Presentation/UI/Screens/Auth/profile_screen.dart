import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Call loadUser  Data when the screen initializes
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
          onPressed: () => Get.offAllNamed('/login'),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.currentUser;
        if (user == null) {
          return const Center(child: Text('Loading user data...'));
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Obx(() {
                      final imageUrl = controller.currentUser?.imageUrl ?? '';
                      final key =
                          ValueKey(imageUrl + DateTime.now().toString());

                      return CircleAvatar(
                        key: key,
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(
                                imageUrl,
                                headers: {'Cache-Control': 'no-cache'},
                              )
                            : null,
                        child: imageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        children: [
                          // Popup menu button for upload and delete options
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onSelected: (value) {
                              if (value == 'upload') {
                                _uploadImage(user.email);
                              } else if (value == 'delete') {
                                _showDeleteConfirmationDialog(
                                    context, user.email);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'upload',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.camera_alt,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Upload Image'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Image'),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome ${user.prenom}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
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
                  onPressed: () {
                    if (user.email.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Email is required to update the profile.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
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

  void _uploadImage(String email) async {
    try {
      await controller.pickImage();
      if (controller.selectedImage != null) {
        await controller.uploadImage(email);
        // Force UI refresh after upload
        controller.update();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String email) {
    Get.defaultDialog(
      title: 'Delete Image',
      middleText: 'Are you sure you want to delete your profile image?',
      onConfirm: () async {
        Get.back();
        await controller.clearImage(email);
        // Close the dialog after the image is cleared
      },
      onCancel: () {
        Get.back(); // Close the dialog when cancel is pressed
      },
      confirmTextColor: Colors.white,
      textConfirm: 'Yes',
      textCancel: 'No',
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}
