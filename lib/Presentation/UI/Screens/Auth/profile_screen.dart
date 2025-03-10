import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/cart_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/ordersList_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/wishlist_page.dart';
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
          // Mes magasins
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite, color: Colors.black),
            title: const Text('Mes favoris'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              final userEmail = controller.currentUser?.email;
              if (userEmail != null) {
                Get.to(() => WishlistPage(userEmail: userEmail));
              } else {
                Get.snackbar('Erreur', 'Veuillez vous connecter d\'abord');
              }
              // Action pour « Mes magasins »
            },
          ),
          Divider(color: Colors.grey[300]),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            title: const Text('Mon panier'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.to(() => CartScreen());
              // Action pour « Mes magasins »
            },
          ),
          Divider(color: Colors.grey[300]),
          // Support
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.store, color: Colors.black),
            title: const Text('Mes commandes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.to(() => OrdersListPage());
            },
          ),
        ],
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Section « Preferences » : toggles (Notifications push, Face ID, Code PIN)
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
            'Préférences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          // Notifications push
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recevoir des notifications'),
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
              'Se Déconnecter',
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
