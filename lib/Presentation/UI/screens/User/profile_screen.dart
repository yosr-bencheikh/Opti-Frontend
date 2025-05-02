import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/cart_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/wishlist_page.dart';
import 'package:opti_app/Presentation/UI/screens/User/ordersList_screen.dart';

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
          return const Center(
              child: Text('Chargement des données utilisateur...'));
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
                // Section « Inventories » : Mes magasins, Support
                _buildInventoriesSection(),
                const SizedBox(height: 24),
                // Section « Preferences » : toggles (Notifications push, Face ID, Code PIN)
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
                        // Appeler la méthode pour choisir une image d'abord
                        await controller.pickImage();
                        if (controller.selectedImage != null) {
                          controller.uploadImage(user.email);
                        } else {
                          Get.snackbar('Erreur', 'Aucune image sélectionnée!');
                        }
                      },
                    ),
                    // Afficher uniquement l'icône de suppression si une image est présente
                    if ((controller.currentUser?.imageUrl ?? '').isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Confirmer",
                            middleText:
                                "Êtes-vous sûr de vouloir supprimer la photo ?",
                            textCancel: "Non",
                            textConfirm: "Oui",
                            onConfirm: () {
                              controller.clearImage(user.email);
                              Get.back(); // Fermer la boîte de dialogue
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
          // Nom de l'utilisateur
          Text(
            user.prenom.isNotEmpty ? user.prenom : 'Nom d\'utilisateur',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          // Email de l'utilisateur
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          // Bouton Edit profile
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
              'Modifier le profil',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Section « Inventories » : Mes magasins, Support
  //------------------------------------------------------------------------------
  Widget _buildInventoriesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Shopping',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          _buildListTile(
            icon: Icons.favorite_border,
            iconColor: Colors.red.shade400,
            title: 'Mes favoris',
            subtitle: 'Articles sauvegardés pour plus tard',
            onTap: () {
              final userEmail = controller.currentUser?.email;
              if (userEmail != null) {
                Get.to(() => WishlistPage(userEmail: userEmail));
              } else {
                Get.snackbar(
                  'Erreur',
                  'Veuillez vous connecter d\'abord',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade400,
                  colorText: Colors.white,
                );
              }
            },
          ),
          const Divider(height: 1, thickness: 1),
          _buildListTile(
            icon: Icons.shopping_cart_outlined,
            iconColor: Colors.blue.shade400,
            title: 'Mon panier',
            subtitle: 'Voir et modifier vos articles',
            onTap: () => Get.to(() => CartScreen()),
          ),
          const Divider(height: 1, thickness: 1),
          _buildListTile(
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.green.shade600,
            title: 'Mes commandes',
            subtitle: 'Suivre vos achats récents',
            onTap: () {
              navigationController.setSelectedIndex(2);
              Get.to(() => OrdersListPage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  //------------------------------------------------------------------------------
  // Bouton « Logout »
  //------------------------------------------------------------------------------
 Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.defaultDialog(
            title: "Confirmation",
            titleStyle: TextStyle(color: Colors.blue.shade700),
            middleText: "Êtes-vous sûr de vouloir vous déconnecter ?",
            textCancel: "Non",
            textConfirm: "Oui",
            confirmTextColor: Colors.white,
            buttonColor: Colors.blue.shade700,
            onConfirm: () {
              controller.logout();
              Get.back();
            },
            cancelTextColor: Colors.blue.shade700,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade200, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Se Déconnecter',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  //------------------------------------------------------------------------------
  // Bottom Navigation
  //------------------------------------------------------------------------------
  Widget _buildBottomNavBar() {
    return Obx(() => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationController.selectedIndex.value,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Magasins'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt), label: 'Commandes'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          onTap: navigationController.changePage,
        ));
  }
}
