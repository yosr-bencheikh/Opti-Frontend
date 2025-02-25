import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/optician_product_screen.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/opticien_controller.dart';

class StoresScreen extends StatelessWidget {
  final NavigationController navigationController = Get.find();
  final OpticienController opticianController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optical Stores'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildOpticalStores(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildOpticalStores() {
    return Obx(() {
      if (opticianController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final opticians = opticianController.opticiensList;

      if (opticians.isEmpty) {
        return const Center(child: Text('No opticians found.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: opticians.length,
        itemBuilder: (context, index) {
          final optician = opticians[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.store, color: Colors.grey),
              ),
              title: Text(
                optician
                    .nom, // Assuming the Optician entity has a name property
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                optician.email, // Assuming a description property
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Navigate to the OpticianProductsScreen and pass the optician ID
                  Get.to(() => OpticianProductsScreen(opticianId: optician.id));
                },
                child: const Text('View Products'),
              ),
            ),
          );
        },
      );
    });
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
