import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/cart_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends GetView<AuthController> {
  // États locaux (Rx) pour les Switch dans « Preferences »
  final RxBool pushNotifications = true.obs;
  final RxBool faceID = false.obs;
  final RxBool pinCode = false.obs;
  final NavigationController navigationController = Get.find();

  @override
  Widget build(BuildContext context) {
    // Charger les données utilisateur si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentUser == null) {
        final userEmail = Get.find<SharedPreferences>().getString('userEmail');
        if (userEmail != null && userEmail.isNotEmpty) {
          controller.loadUserData(userEmail);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        // Affichage d'un indicateur de chargement pendant les requêtes
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Récupération de l'utilisateur actuel
        final User? user = controller.currentUser;
        if (user == null) {
          return const Center(child: Text('Loading user data...'));
        }

        // Construction de l'interface principale
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                // En-tête : avatar, nom, email, bouton « Edit profile »
                _buildProfileHeader(context, user),
                const SizedBox(height: 24),
                // Section « Inventories » : My stores, Support
                _buildInventoriesSection(),
                const SizedBox(height: 24),
                // Section « Preferences » : toggles (Push notifications, Face ID, PIN code)
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                // Bouton « Logout »
                _buildLogoutButton(),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  //------------------------------------------------------------------------------
  // En-tête avec la photo de profil, nom, email et bouton « Edit profile »
  //------------------------------------------------------------------------------
  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar with Stack for upload/clear icons
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (controller.currentUser?.imageUrl ?? '').isNotEmpty
                        ? NetworkImage(
                            controller.currentUser!.imageUrl,
                            headers: {'Cache-Control': 'no-cache'},
                          )
                        : null,
                child: (controller.currentUser?.imageUrl ?? '').isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.blueAccent),
                      onPressed: () async {
                        // Call method to pick an image first
                        await controller.pickImage();
                        if (controller.selectedImage != null) {
                          controller.uploadImage(user.email);
                        } else {
                          Get.snackbar('Error', 'No image selected!');
                        }
                      },
                    ),
                    // Only show clear icon if an image is present
                    if ((controller.currentUser?.imageUrl ?? '').isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Confirm",
                            middleText:
                                "Are you sure you want to delete the picture?",
                            textCancel: "No",
                            textConfirm: "Yes",
                            onConfirm: () {
                              controller.clearImage(user.email);
                              Get.back(); // Close the dialog
                            },
                            onCancel: () {},
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // User name
          Text(
            user.prenom.isNotEmpty ? user.prenom : 'User Name',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          // User email
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          // Edit profile button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.to(() => UpdateProfileScreen(email: user.email));
            },
            child: const Text(
              'Edit profile',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Section « Inventories » : My stores, Support
  //------------------------------------------------------------------------------
  Widget _buildInventoriesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shopping',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // My stores
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite, color: Colors.black),
            title: const Text('My favourites'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              final userEmail = controller.currentUser?.email;
              if (userEmail != null) {
                Get.to(() => WishlistPage(userEmail: userEmail));
              } else {
                Get.snackbar('Error', 'Please log in first');
              }
              // Action pour « My stores »
            },
          ),
          Divider(color: Colors.grey[300]),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            title: const Text('My cart'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.to(() => CartScreen());
              // Action pour « My stores »
            },
          ),
          Divider(color: Colors.grey[300]),
          // Support
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.store, color: Colors.black),
            title: const Text('My recent purchases'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Action pour « Support »
            },
          ),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Section « Preferences » : toggles (Push notifications, Face ID, PIN code)
  //------------------------------------------------------------------------------
  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          // Push notifications
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recieve notifications'),
              value: pushNotifications.value,
              onChanged: (val) => pushNotifications.value = val,
            ),
          ),

          // Face ID
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Bouton « Logout »
  //------------------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        Get.defaultDialog(
          title: "Confirm Logout",
          middleText: "Are you sure you want to log out?",
          textCancel: "No",
          textConfirm: "Yes",
          confirmTextColor: Colors.white,
          onConfirm: () {
            controller.logout();
            Get.back(); // Close the dialog
          },
          onCancel: () {},
          barrierDismissible: false, // Prevent dismissing by tapping outside
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Obx(() => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationController.selectedIndex.value,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stores'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: navigationController.changePage,
        ));
  }
}
