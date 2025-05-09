import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/UsersScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/domain/entities/Order.dart';

class OpticienOrdersPage extends StatefulWidget {
  const OpticienOrdersPage({Key? key}) : super(key: key);

  @override
  State<OpticienOrdersPage> createState() => _OpticienOrdersPageState();
}

class _OpticienOrdersPageState extends State<OpticienOrdersPage> {
  final OrderController orderController = Get.find<OrderController>();
  final List<String> statusOptions = [
    'En attente',
    'Confirmée',
    'Livrée',
    'Annulée'
  ];

  final List<String> cancellationReasons = [
    'Rupture de stock',
    'Client indisponible',
    'Problème de paiement',
    'Autre raison',
  ];
  String? _selectedUserId;
  DateTime? _selectedUserTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.loadOrdersForCurrentOpticianWithDetails();
    });
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
            onPressed: () =>
                orderController.loadOrdersForCurrentOpticianWithDetails(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          CustomSidebar(currentPage: 'Orders'), // Use CustomSidebar here

          // Main content
          Expanded(
            child: Obx(() {
              if (orderController.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.indigo.shade700),
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
                    ],
                  ),
                );
              }

              // Filter orders
              final activeOrders = orderController.allOrders
                  .where((order) => order.status != 'Completée')
                  .toList();
              final completedOrders = orderController.allOrders
                  .where((order) => order.status == 'Completée')
                  .toList();

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade100, Colors.white],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stats row
                        _buildStatsRow(),
                        SizedBox(height: 24),

                        // Active Orders Section
                        if (activeOrders.isNotEmpty) ...[
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 16.0),
                            child: Text(
                              'Commandes en Cours',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.indigo.shade50),
                                  dataRowMaxHeight: 80,
                                  dataRowMinHeight: 60,
                                  columnSpacing: 20,
                                  horizontalMargin: 20,
                                  dividerThickness: 1.5,
                                  headingTextStyle: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  dataTextStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text('ID',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('ID Client',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Date',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Statut',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Actions',
                                          textAlign: TextAlign.center),
                                    ),
                                  ],
                                  rows: activeOrders.map((order) {
                                    final dateFormat =
                                        DateFormat('dd/MM/yyyy HH:mm');
                                    final formattedDate =
                                        dateFormat.format(order.createdAt);
                                    final rowColor = _determineRowColor(order);

                                    return DataRow(
                                      color:
                                          MaterialStateProperty.all(rowColor),
                                      cells: [
                                        DataCell(
                                          Text(
                                            order.id?.substring(0, 8) ?? 'N/A',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'RobotoMono',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              _handleUserSelection(
                                                  order.userId);
                                              Get.to(() => UsersScreen(
                                                  selectedUserId:
                                                      order.userId));
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Text(
                                                order.userId.substring(0, 8),
                                                style: TextStyle(
                                                  color: Colors.indigo.shade700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontSize: 14,
                                                  fontWeight: _selectedUserId ==
                                                          order.userId
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
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                              child: _buildStatusChip(
                                                  order.status)),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildActionButton(
                                                icon: Icons.visibility,
                                                color: Colors.indigo.shade600,
                                                tooltip: 'Voir les détails',
                                                onPressed: () =>
                                                    _showOrderDetails(order),
                                                iconSize: 24,
                                              ),
                                              // Ne montre le bouton modifier que si le statut n'est pas Annulée
                                              if (order.status != 'Annulée')
                                                _buildActionButton(
                                                  icon: Icons.edit,
                                                  color: Colors.amber.shade700,
                                                  tooltip: 'Modifier le statut',
                                                  onPressed: () =>
                                                      _showStatusUpdateDialog(
                                                          order),
                                                  iconSize: 24,
                                                ),
                                              if (order.status ==
                                                  'En attente') ...[
                                                _buildActionButton(
                                                  icon: Icons.check_circle,
                                                  color: Colors.green.shade600,
                                                  tooltip: 'Accepter',
                                                  onPressed: () =>
                                                      _updateOrderStatus(
                                                          order, 'Confirmée'),
                                                  iconSize: 24,
                                                ),
                                                _buildActionButton(
                                                  icon: Icons.cancel,
                                                  color: Colors.red.shade600,
                                                  tooltip: 'Refuser',
                                                  onPressed: () =>
                                                      _updateOrderStatus(
                                                          order, 'Annulée'),
                                                  iconSize: 24,
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
                        ],
                        SizedBox(height: 20), // Consistent spacing

                        // Completed Orders Section
                        if (completedOrders.isNotEmpty) ...[
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 16.0),
                            child: Text(
                              'Historique des Commandes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.green.shade50),
                                  dataRowMaxHeight: 70,
                                  dataRowMinHeight: 55,
                                  columnSpacing: 20,
                                  horizontalMargin: 20,
                                  dividerThickness: 1.5,
                                  headingTextStyle: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  dataTextStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text('ID',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('ID Client',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Date',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Articles',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Total',
                                          textAlign: TextAlign.center),
                                    ),
                                    DataColumn(
                                      label: Text('Actions',
                                          textAlign: TextAlign.center),
                                    ),
                                  ],
                                  rows: completedOrders.map((order) {
                                    final dateFormat =
                                        DateFormat('dd/MM/yyyy HH:mm');
                                    final formattedDate =
                                        dateFormat.format(order.createdAt);

                                    return DataRow(
                                      color: MaterialStateProperty.all(Colors
                                          .green.shade50
                                          .withOpacity(0.3)),
                                      cells: [
                                        DataCell(
                                          Text(
                                            order.id?.substring(0, 8) ?? 'N/A',
                                            style: TextStyle(
                                              fontFamily: 'RobotoMono',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              Get.to(() => UsersScreen(
                                                  selectedUserId:
                                                      order.userId));
                                            },
                                            child: Text(
                                              order.userId.substring(0, 8),
                                              style: TextStyle(
                                                color: Colors.indigo.shade700,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(formattedDate),
                                        ),
                                        DataCell(
                                          Text(
                                              '${order.items.length} article(s)'),
                                        ),
                                        DataCell(
                                          Text(
                                            '${order.total.toStringAsFixed(2)} €',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo.shade700,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              _buildActionButton(
                                                icon: Icons.visibility,
                                                color: Colors.indigo.shade600,
                                                tooltip: 'Voir les détails',
                                                onPressed: () =>
                                                    _showOrderDetails(order,
                                                        showModifyButtons:
                                                            false),
                                                iconSize: 22,
                                              ),
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
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // Count orders by status
    int pendingCount = 0;
    int confirmedCount = 0;
    int deliveryCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    for (var order in orderController.allOrders) {
      switch (order.status) {
        case 'En attente':
          pendingCount++;
          break;
        case 'Confirmée':
          confirmedCount++;
          break;
        case 'En livraison':
          deliveryCount++;
          break;
        case 'Completée':
          completedCount++;
          break;
        case 'Annulée':
          cancelledCount++;
          break;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the cards
        children: [
          _buildStatCard(
            title: 'En attente',
            count: pendingCount,
            color: Colors.orange,
            icon: Icons.hourglass_top,
          ),
          _buildStatCard(
            title: 'Confirmées',
            count: confirmedCount,
            color: Colors.blue,
            icon: Icons.check_circle_outline,
          ),
          _buildTotalCard(
            count: orderController.allOrders.length,
          ), // Total card in the center
          _buildStatCard(
            title: 'En livraison',
            count: deliveryCount,
            color: Colors.purple,
            icon: Icons.local_shipping,
          ),
          _buildStatCard(
            title: 'Completée',
            count: completedCount,
            color: Colors.green,
            icon: Icons.done_all,
          ),
          _buildStatCard(
            title: 'Annulées',
            count: cancelledCount,
            color: Colors.red,
            icon: Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 120, // Smaller width for status cards
      margin: EdgeInsets.symmetric(horizontal: 8), // Add horizontal spacing
      child: Card(
        elevation: 8, // Increased elevation for a more pronounced shadow
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20), // More pronounced rounded corners
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(20), // Match the card's border radius
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28), // Slightly larger icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14, // Slightly larger font size
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600, // Bolder font weight
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 24, // Slightly larger font size
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard({required int count}) {
    return Container(
      width: 160, // Larger width for the total card
      margin: EdgeInsets.symmetric(horizontal: 8), // Add horizontal spacing
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.indigo.shade700,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shopping_cart_checkout,
                  color: Colors.white.withOpacity(0.8),
                  size: 32), // Larger icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Commandes',
                    style: TextStyle(
                      fontSize: 14, // Larger font size
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 28, // Larger font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required String tooltip,
      required VoidCallback onPressed,
      required int iconSize}) {
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
    final allowedStatuses = getAllowedStatuses(order.status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le statut'),
        content: Container(
          width: double.minPositive,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: allowedStatuses.map((status) {
              return ListTile(
                title: Text(status),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  child: Icon(_getStatusIcon(status),
                      color: _getStatusColor(status), size: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (status == 'Annulée') {
                    _showCancellationReasonDialog(order);
                  } else {
                    _updateOrderStatus(order, status);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showCancellationReasonDialog(Order order) {
    String? selectedReason;
    final TextEditingController customReasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Raison d\'annulation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...cancellationReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    );
                  }).toList(),
                  if (selectedReason == 'Autre raison')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: customReasonController,
                        decoration: InputDecoration(
                          labelText: 'Précisez la raison',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reason = selectedReason == 'Autre raison'
                        ? customReasonController.text
                        : selectedReason;
                    if (reason != null && reason.isNotEmpty) {
                      Navigator.pop(context);
                      _updateOrderStatus(order, 'Annulée',
                          cancellationReason: reason);
                    }
                  },
                  child: Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
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

  void _updateOrderStatus(Order order, String newStatus,
      {String? cancellationReason}) async {
    final success = await orderController.updateOrderStatus(
      order.id!,
      newStatus,
      cancellationReason: cancellationReason,
    );
    if (success) {
      orderController.updateLocalOrderStatus(order.id!, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Statut de la commande mis à jour: $newStatus')),
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

  void _showOrderDetails(Order order, {bool showModifyButtons = true}) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
          child: SingleChildScrollView(
            // Make the content scrollable
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                            Get.to(() =>
                                UsersScreen(selectedUserId: order.userId));
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
                  if (showModifyButtons && order.status == 'En attente')
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
                  else if (showModifyButtons)
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
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(
      {required String title, required IconData icon, required Widget child}) {
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

  List<String> getAllowedStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'En attente':
        return ['Confirmée', 'Annulée'];
      case 'Confirmée':
        return ['En livraison', 'Annulée'];
      case 'En livraison':
        return ['Completée', 'Annulée'];
      case 'Completée':
        return [];
      case 'Annulée':
        return [];
      default:
        return [];
    }
  }
}
