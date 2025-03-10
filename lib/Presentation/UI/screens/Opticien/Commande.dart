import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/UsersScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
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
    'Livrée',
    'Annulée'
  ];

  String? _selectedUserId;
  DateTime? _selectedUserTimestamp;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    await orderController.loadAllOrders();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'Confirmée':
        return Colors.blue;
      case 'Livrée':
        return Colors.green;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 22),
          SizedBox(width: 12),
          Text(
            'Gestion Commandes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () => orderController.loadAllOrders(),
          tooltip: 'Actualiser',
        ),
      ],
    ),
    body: Row(
      children: [
        // Add the CustomSidebar here
        CustomSidebar(currentPage: 'Orders'),

        // Main content
        Expanded(
          child: Obx(() {
            if (orderController.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade700),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des commandes...',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (orderController.allOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune commande disponible',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => orderController.loadAllOrders(),
                      icon: Icon(Icons.refresh),
                      label: Text('Actualiser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade100, Colors.white],
                  stops: [0.0, 0.3],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    _buildStatsRow(),
                    SizedBox(height: 24),

                    // Table title
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        'Liste des commandes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    // Orders table
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
                              dataRowMaxHeight: 100, // Augmenté de 80 à 100
                              dataRowMinHeight: 60, // Ajout d'une hauteur minimale
                              columnSpacing: 20, // Augmenté de 16 à 20
                              horizontalMargin: 20, // Augmenté de 16 à 20
                              dividerThickness: 1.5, // Ajout pour améliorer la séparation visuelle
                              headingTextStyle: TextStyle(
                                color: const Color.fromARGB(255, 12, 12, 12),
                                fontWeight: FontWeight.w600,
                                fontSize: 16, // Augmenté de 14 à 16
                              ),
                              dataTextStyle: TextStyle(
                                fontSize: 14, // Ajout pour augmenter la taille du texte des données
                              ),
                              columns: const [
                                DataColumn(
                                  label: Expanded(
                                    child: Text('ID', textAlign: TextAlign.center),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('ID Client', textAlign: TextAlign.center),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Date', textAlign: TextAlign.center),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Statut', textAlign: TextAlign.center),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Actions', textAlign: TextAlign.center),
                                  ),
                                ),
                              ],
                              rows: orderController.allOrders.map((order) {
                                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                                final formattedDate = dateFormat.format(order.createdAt);
                                final rowColor = _determineRowColor(order);

                                return DataRow(
                                  color: MaterialStateProperty.all(rowColor),
                                  cells: [
                                    DataCell(
                                      Text(
                                        order.id?.substring(0, 8) ?? 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'RobotoMono',
                                          fontSize: 14, // Augmenté de 12 à 14
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      GestureDetector(
                                        onTap: () {
                                          _handleUserSelection(order.userId);
                                          Get.to(() => UsersScreen(selectedUserId: order.userId));
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0), // Ajout de padding
                                          child: Text(
                                            order.userId.substring(0, 8),
                                            style: TextStyle(
                                              color: Colors.indigo.shade700,
                                              decoration: TextDecoration.underline,
                                              fontSize: 14, // Ajout de taille de police
                                              fontWeight: _selectedUserId == order.userId
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 14, // Augmenté de 13 à 14
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(child: _buildStatusChip(order.status)), // Centrage du chip
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Modifié pour mieux répartir
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.visibility,
                                            color: Colors.indigo.shade600,
                                            tooltip: 'Voir les détails',
                                            onPressed: () => _showOrderDetails(order),
                                            iconSize: 24, // Ajout d'une taille d'icône
                                          ),
                                          _buildActionButton(
                                            icon: Icons.edit,
                                            color: Colors.amber.shade700,
                                            tooltip: 'Modifier le statut',
                                            onPressed: () => _showStatusUpdateDialog(order),
                                            iconSize: 24, // Ajout d'une taille d'icône
                                          ),
                                          if (order.status == 'En attente') ...[
                                            _buildActionButton(
                                              icon: Icons.check_circle,
                                              color: Colors.green.shade600,
                                              tooltip: 'Accepter',
                                              onPressed: () => _updateOrderStatus(order, 'Confirmée'),
                                              iconSize: 24, // Ajout d'une taille d'icône
                                            ),
                                            _buildActionButton(
                                              icon: Icons.cancel,
                                              color: Colors.red.shade600,
                                              tooltip: 'Refuser',
                                              onPressed: () => _updateOrderStatus(order, 'Annulée'),
                                              iconSize: 24, // Ajout d'une taille d'icône
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => orderController.loadAllOrders(),
      backgroundColor: Colors.indigo.shade700,
      tooltip: 'Actualiser les commandes',
      elevation: 4,
      child: const Icon(Icons.refresh, color: Colors.white),
    ),
  );
}

  Widget _buildStatsRow() {
    // Count orders by status
    int pendingCount = 0;
    int confirmedCount = 0;
    int deliveredCount = 0;
    int cancelledCount = 0;

    for (var order in orderController.allOrders) {
      if (order.status == 'En attente') pendingCount++;
      if (order.status == 'Confirmée') confirmedCount++;
      if (order.status == 'Livrée') deliveredCount++;
      if (order.status == 'Annulée') cancelledCount++;
    }

    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('En attente', pendingCount, Colors.orange),
          _buildStatCard('Confirmées', confirmedCount, Colors.blue),
          _buildStatCard('Livrées', deliveredCount, Colors.green),
          _buildStatCard('Annulées', cancelledCount, Colors.red),
          _buildStatCard('Total', orderController.allOrders.length, Colors.indigo.shade700),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        width: 140,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required Color color, 
    required String tooltip, 
    required VoidCallback onPressed, required int iconSize
  }) {
    return Container(
      margin: EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _determineRowColor(Order order) {
    Color rowColor = Colors.white;

    // Base color selection based on order status
    if (order.status == 'En attente') {
      rowColor = Colors.amber.shade50.withOpacity(0.3);
    } else if (order.status == 'Confirmée') {
      rowColor = Colors.blue.shade50.withOpacity(0.3);
    } else if (order.status == 'Livrée') {
      rowColor = Colors.green.shade50.withOpacity(0.3);
    } else if (order.status == 'Annulée') {
      rowColor = Colors.red.shade50.withOpacity(0.3);
    }

    // If the user is selected and it's within 3 seconds, highlight the row
    if (_selectedUserId == order.userId &&
        _selectedUserTimestamp != null &&
        DateTime.now().difference(_selectedUserTimestamp!).inSeconds < 3) {
      rowColor = Colors.indigo.shade100;
    }

    return rowColor;
  }

  void _showStatusUpdateDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le statut'),
        content: Container(
          width: double.minPositive,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOptions.map((status) {
              return ListTile(
                title: Text(status),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 18),
                ),
                selected: order.status == status,
                selectedTileColor: Colors.grey.shade100,
                onTap: () {
                  Navigator.pop(context);
                  _updateOrderStatus(order, status);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'En attente':
        return Icons.hourglass_empty;
      case 'Confirmée':
        return Icons.check_circle_outline;
      case 'Livrée':
        return Icons.local_shipping_outlined;
      case 'Annulée':
        return Icons.cancel_outlined;
      default:
        return Icons.circle;
    }
  }

  void _updateOrderStatus(Order order, String newStatus) async {
    final success = await orderController.updateOrderStatus(order.id!, newStatus);
    if (success) {
      orderController.updateLocalOrderStatus(order.id!, newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Statut de la commande mis à jour: $newStatus')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(8),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Erreur lors de la mise à jour du statut')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(8),
        ),
      );
    }
  }

  void _handleUserSelection(String userId) {
    setState(() {
      _selectedUserId = userId;
      _selectedUserTimestamp = DateTime.now();
    });

    // Reset selection after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _selectedUserId = null;
          _selectedUserTimestamp = null;
        });
      }
    });
  }

  void _showOrderDetails(Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Handle indicator
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                
                // Content
                SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 24,
                                color: Colors.indigo.shade700,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Détails de la commande',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade800,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Order ID and Date
                      _buildDetailCard(
                        title: 'Informations générales',
                        icon: Icons.info_outline,
                        child: Column(
                          children: [
                            _buildDetailRow(
                              title: 'ID Commande',
                              value: '#${order.id?.substring(0, 8) ?? 'N/A'}',
                              valueStyle: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Divider(),
                            _buildDetailRow(
                              title: 'Date de commande',
                              value: dateFormat.format(order.createdAt),
                            ),
                            Divider(),
                            _buildDetailRow(
                              title: 'ID Client',
                              value: order.userId,
                              valueStyle: TextStyle(
                                color: Colors.indigo.shade700,
                                decoration: TextDecoration.underline,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => UsersScreen(selectedUserId: order.userId));
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Delivery Information
                      _buildDetailCard(
                        title: 'Informations de livraison',
                        icon: Icons.local_shipping_outlined,
                        child: Column(
                          children: [
                            _buildDetailRow(
                              title: 'Adresse de livraison',
                              value: order.address,
                            ),
                            Divider(),
                            _buildDetailRow(
                              title: 'Méthode de paiement',
                              value: order.paymentMethod,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Ordered Items
                      _buildDetailCard(
                        title: 'Articles commandés',
                        icon: Icons.shopping_bag_outlined,
                        child: Column(
                          children: [
                            ...order.items.map((item) => Column(
                              children: [
                                _buildOrderItemRow(item),
                                if (order.items.last != item) Divider(),
                              ],
                            )),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Order Summary
                      _buildDetailCard(
                        title: 'Résumé financier',
                        icon: Icons.payments_outlined,
                        child: Column(
                          children: [
                            _buildDetailRow(
                              title: 'Sous-total',
                              value: '${order.subtotal.toStringAsFixed(2)} €',
                            ),
                            Divider(),
                            _buildDetailRow(
                              title: 'Frais de livraison',
                              value: '${order.deliveryFee.toStringAsFixed(2)} €',
                            ),
                            Divider(),
                            _buildDetailRow(
                              title: 'Total',
                              value: '${order.total.toStringAsFixed(2)} €',
                              valueStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Action Buttons
                      if (order.status == 'En attente')
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.check_circle),
                                    label: Text(
                                      'Accepter la commande',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _updateOrderStatus(order, 'Confirmée');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.cancel_outlined),
                                    label: Text(
                                      'Refuser la commande',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      side: BorderSide(color: Colors.red.shade300),
                                      minimumSize: Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _updateOrderStatus(order, 'Annulée');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.edit_outlined),
                                label: Text(
                                  'Modifier le statut',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.indigo.shade700,
                                  side: BorderSide(color: Colors.indigo.shade300),
                                  minimumSize: Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showStatusUpdateDialog(order);
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.indigo.shade700,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    TextStyle? valueStyle,
    VoidCallback? onTap,
  }) {
    Widget valueWidget = Text(
      value,
      style: valueStyle ?? TextStyle(fontWeight: FontWeight.w500),
    );

    if (onTap != null) {
      valueWidget = GestureDetector(
        onTap: onTap,
        child: valueWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 16),
          Flexible(child: valueWidget),
        ],
      ),
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