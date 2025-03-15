import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/domain/entities/Order.dart';

class OrdersListPage extends StatelessWidget {
  final OrderController orderController = Get.find();
  final AuthController userController = Get.find();
  final NavigationController navigationController = Get.find();

  OrdersListPage({Key? key}) : super(key: key) {
    // Improved logging and error handling
    final currentUser = userController.currentUser;

    if (currentUser != null && currentUser.id != null) {
      print('Initializing OrdersListPage for user: ${currentUser.id}');
      orderController.loadUserOrders(currentUser.id!);
    } else {
      print('Cannot load orders: No current user or user ID is null');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les commandes. Utilisateur non connecté.',
        duration: const Duration(seconds: 3),
      );
      // Optionally, navigate to login page or show a different screen
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Mes Commandes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Obx(() => Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                    SizedBox(width: 5),
                    Text(
                      '${orderController.userOrders.length} Commandes',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )),
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (orderController.userOrders.isEmpty) {
          return _buildEmptyOrderState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orderController.userOrders.length,
          itemBuilder: (context, index) {
            final order = orderController.userOrders[index];
            return _buildOrderCard(order, context);
          },
        );
      }),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildEmptyOrderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 100, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'Aucune commande pour le moment',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, BuildContext context) {
    return GestureDetector(
      onTap: () => _showOrderDetailsBottomSheet(order, context),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Create a Column for Order ID and Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commande #${order.id}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4), // Add some space between ID and status
                  _buildStatusBadge(order.status ?? 'En attente'),
                ],
              ),
              SizedBox(height: 8),
              Text(
                order.items.map((item) => item.productName).join(', '),
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              // Wrap the bottom row to prevent overflow
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Text(
                    '${order.total.toStringAsFixed(2)} TND',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColors = {
      'En attente': Colors.yellow.shade700,
      'Confirmée': Colors.green.shade700,
      'Annulée': Colors.red.shade700,
      'Livrée': Colors.blue.shade700,
    };

    final statusIcons = {
      'En attente': Icons.access_time,
      'Confirmée': Icons.check_circle,
      'Annulée': Icons.cancel,
      'Livrée': Icons.delivery_dining,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (statusColors[status] ?? Colors.grey.shade700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(statusIcons[status] ?? Icons.help_outline,
              color: statusColors[status] ?? Colors.grey.shade700, size: 16),
          SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: statusColors[status] ?? Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Magasins'),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          onTap: navigationController.changePage,
        ));
  }

  void _showOrderDetailsBottomSheet(Order order, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Détails de la commande',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildOrderDetailsSection(order),
              SizedBox(height: 16),
              if (order.status == 'En attente')
                ElevatedButton(
                  onPressed: () => _cancelOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Annuler la commande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection(Order order) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.list,
            label: 'Articles',
            content: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} (x${item.quantity})',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text('${item.totalPrice.toStringAsFixed(2)} €'),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          Divider(height: 24, color: Colors.grey.shade300),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Total',
            content: Text(
              '${order.total.toStringAsFixed(2)} €',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700),
            ),
          ),
          Divider(height: 24, color: Colors.grey.shade300),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Adresse',
            content: Text(order.address ?? 'Non spécifiée'),
          ),
          Divider(height: 24, color: Colors.grey.shade300),
          _buildDetailRow(
            icon: Icons.payment,
            label: 'Méthode de paiement',
            content: Text(order.paymentMethod ?? 'Non spécifiée'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      {required IconData icon,
      required String label,
      required Widget content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              content,
            ],
          ),
        ),
      ],
    );
  }

  void _cancelOrder(Order order) {
    orderController.deleteOrder(order.id!).then((success) {
      if (success) {
        Get.back(); // Close the bottom sheet
      }
    });
  }
}
