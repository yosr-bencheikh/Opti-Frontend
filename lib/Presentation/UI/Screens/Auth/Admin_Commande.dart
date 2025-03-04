import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/auth/UsersScreen.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/domain/entities/Order.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final OrderController orderController = Get.find<OrderController>();
  final List<String> statusOptions = [
    'En attente',
    'Confirmée',
    'En préparation',
    'En livraison',
    'Livrée',
    'Annulée'
  ];
// Nouvelle variable pour suivre l'ID du client sélectionné
  String? _selectedUserId;
  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    await orderController.loadAllOrders();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
  title: Row(
    children: [
      Icon(Icons.shopping_cart, color: Colors.white), // Icône personnalisée
      SizedBox(width: 8),
      const Text('Administration des Commandes'),
    ],
  ),
  centerTitle: true,
  elevation: 4, // Ombre légère pour un effet de profondeur
),
    body: Obx(() {
      if (orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }


      if (orderController.allOrders.isEmpty) {
        return const Center(
          child: Text(
            'Aucune commande disponible',
            style: TextStyle(fontSize: 18),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du tableau

            // Contenu du tableau
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 73, 139, 224)),
                borderRadius: BorderRadius.circular(8),
              ),
              headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
              dataRowMaxHeight: 80,
              columns: const [
                    DataColumn(
                      label: Text(
                        'ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'ID Client',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Statut',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: orderController.allOrders.map((order) {
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    final formattedDate = dateFormat.format(order.createdAt);

                    Color rowColor = Colors.white;
                    if (order.status == 'En attente') {
                      rowColor = Colors.amber.shade50;
                    } else if (order.status == 'Confirmée' || order.status == 'En préparation') {
                      rowColor = Colors.blue.shade50;
                    } else if (order.status == 'Livrée') {
                      rowColor = Colors.green.shade50;
                    } else if (order.status == 'Annulée') {
                      rowColor = Colors.red.shade50;
                    }
                     if (_selectedUserId == order.userId) {
                        rowColor = Colors.blue.shade100;
                      }
                    return DataRow(
                      color: MaterialStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Text(
                            order.id?.substring(0, 8) ?? 'N/A',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                         DataCell(
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUserId = order.userId;
                                });
                                // Navigation vers l'écran utilisateur
                                Get.to(() => UsersScreen());
                              },
                              child: Text(
                                order.userId.substring(0, 8),
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        DataCell(Text(formattedDate)),
                        DataCell(
                          Text(
                            order.status,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
IconButton(
  icon: const Icon(Icons.visibility, color: Colors.blue),
  onPressed: () => _showOrderDetails(order),
  tooltip: 'Voir les détails',
  hoverColor: Colors.blue.shade100, // Effet de hover
),
PopupMenuButton<String>(
  tooltip: 'Changer le statut',
  icon: const Icon(Icons.edit, color: Colors.orange),
  onSelected: (String newStatus) {
    _updateOrderStatus(order, newStatus);
  },
  itemBuilder: (BuildContext context) {
    return statusOptions.map((String status) {
      return PopupMenuItem<String>(
        value: status,
        child: Text(status),
      );
    }).toList();
  },
),
if (order.status == 'En attente') ...[
  IconButton(
    icon: const Icon(Icons.check_circle, color: Colors.green),
    onPressed: () => _updateOrderStatus(order, 'Confirmée'),
    tooltip: 'Accepter',
  ),
  IconButton(
    icon: const Icon(Icons.cancel, color: Colors.red),
    onPressed: () => _updateOrderStatus(order, 'Annulée'),
    tooltip: 'Refuser',
  ),
],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }),
    floatingActionButton: FloatingActionButton(
  onPressed: () => orderController.loadAllOrders(),
  child: const Icon(Icons.refresh, color: Colors.white),
  backgroundColor: Colors.blue, // Couleur plus vive
  tooltip: 'Actualiser les commandes',
  elevation: 6, // Ombre plus prononcée
),
  );
}

  
Color _getStatusColor(String status) {
  switch (status) {
    case 'En attente':
      return Colors.orange.shade800;
    case 'Confirmée':
      return Colors.blue.shade800;
    case 'En préparation':
      return Colors.purple.shade800;
    case 'En livraison':
      return Colors.cyan.shade900;
    case 'Livrée':
      return Colors.green.shade800;
    case 'Annulée':
      return Colors.red.shade800;
    default:
      return Colors.grey.shade800;
  }
}
  void _updateOrderStatus(Order order, String newStatus) async {
    final success = await orderController.updateOrderStatus(order.id!, newStatus);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de la commande mis à jour: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  backgroundColor: Colors.grey[50], // Fond plus doux
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    minChildSize: 0.4,
    expand: false,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text(
              'Commande #${order.id?.substring(0, 8) ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto', // Police moderne
              ),
            ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Informations',
                    [
                      'Client: ${order.userId}',
                      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                      'Adresse: ${order.address}',
                      'Paiement: ${order.paymentMethod}',
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Articles commandés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => _buildOrderItemRow(item)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Résumé',
                    [
                      'Sous-total: ${order.subtotal.toStringAsFixed(2)} €',
                      'Frais de livraison: ${order.deliveryFee.toStringAsFixed(2)} €',
                      'Total: ${order.total.toStringAsFixed(2)} €',
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (order.status == 'En attente') ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Accepter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(order, 'Confirmée');
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cancel),
                            label: const Text('Refuser'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(order, 'Annulée');
                            },
                          ),
                        ] else ...[
                          OutlinedButton(
                            child: const Text('Fermer'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item),
        )),
      ],
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: item.productImage.isNotEmpty
                  ? Image.network(item.productImage, fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Prix unitaire: ${item.unitPrice.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${item.totalPrice.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}