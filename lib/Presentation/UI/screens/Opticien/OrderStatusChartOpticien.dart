import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';

class OrderStatusChart extends StatefulWidget {
  const OrderStatusChart({Key? key}) : super(key: key);

  @override
  State<OrderStatusChart> createState() => _OrderStatusChartState();
}

class _OrderStatusChartState extends State<OrderStatusChart>
    with SingleTickerProviderStateMixin {
  final OrderController _orderController = Get.find<OrderController>();
  int touchedIndex = -1;
  String? selectedStatus;
  String selectedMonth = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool showDetailView = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set initial month to current month
    selectedMonth = DateFormat('MMMM').format(DateTime.now());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView(String status) {
    setState(() {
      if (selectedStatus == status && showDetailView) {
        // If already showing details for this status, go back to overview
        showDetailView = false;
        selectedStatus = null;
        _animationController.reverse();
      } else {
        // Show details for this status
        showDetailView = true;
        selectedStatus = status;
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_orderController.allOrders.isEmpty) {
        return const Center(child: Text('Aucune commande disponible'));
      }

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title with back button when in detail view
              _buildHeader(),

              // Content with animation between views
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return showDetailView
                      ? FadeTransition(
                          opacity: _animation,
                          child: _buildDetailView(),
                        )
                      : FadeTransition(
                          opacity: Tween<double>(begin: 1.0, end: 0.0)
                              .animate(_animation),
                          child: _buildOverviewChart(),
                        );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showDetailView)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _toggleView(selectedStatus!);
            },
          )
        else
          const SizedBox(width: 40), // Placeholder for alignment

        Text(
          showDetailView
              ? 'Commandes ${selectedStatus ?? ""}'
              : 'Statut des commandes',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 40), // Placeholder for alignment
      ],
    );
  }

  Widget _buildOverviewChart() {
    // Préparer les données pour le graphique
    final statusData = _prepareStatusData();

    return Column(
      children: [
        SizedBox(
          height: 310,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }

                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;

                    // Handle tap on release
                    if (event is FlTapUpEvent && touchedIndex >= 0) {
                      final statusList = statusData.keys.toList();
                      if (touchedIndex < statusList.length) {
                        _toggleView(statusList[touchedIndex]);
                      }
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              sections: _getSections(statusData),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(statusData),
      ],
    );
  }

  Widget _buildDetailView() {
    if (selectedStatus == null) return const SizedBox();

    // Build the month dropdown with only months that have orders for this status
    return Column(
      mainAxisSize: MainAxisSize.min, // Make Column wrap its content
      children: [
        _buildMonthDropdownForStatus(),
        const SizedBox(height: 20),
        SizedBox(
          height: 300, // Fixed height for the chart
          child: _buildOrdersChartForStatusAndMonth(),
        ),
      ],
    );
  }

  Widget _buildOrdersChartForStatusAndMonth() {
    final selectedMonthNumber = DateFormat('MMMM').parse(selectedMonth).month;

    // Filter orders by status and selected month
    final filteredOrders = _orderController.allOrders.where((order) {
      final orderStatus = (order.status == null || order.status.isEmpty)
          ? 'Non défini'
          : _formatStatus(order.status);

      return orderStatus == selectedStatus &&
          order.createdAt.month == selectedMonthNumber;
    }).toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text('Aucune commande pour ce statut ce mois-ci'),
      );
    }

    // Calculate total revenue
    final double totalRevenue =
        filteredOrders.fold(0, (sum, order) => sum + order.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue header (remains fixed)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${totalRevenue.toStringAsFixed(2)} TND',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Total Revenue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Scrollable container for the orders
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: filteredOrders.map((order) {
                final dateString =
                    DateFormat('dd/MM/yy').format(order.createdAt);
                final orderTotal = order.total;
                final fractionOfTotal =
                    totalRevenue > 0 ? orderTotal / totalRevenue : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalWidth = constraints.maxWidth;
                              final fillWidth = fractionOfTotal * totalWidth;

                              return Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    width: fillWidth,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 236, 238, 89),
                                          Color.fromARGB(255, 229, 140, 24)
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        '${orderTotal.toStringAsFixed(2)} TND',
                                        style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 140, 66, 66),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateString,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final statusColors = _getStatusColors();
    return statusColors[status] ?? Colors.grey;
  }

  Widget _buildMonthDropdownForStatus() {
    // Get unique months that have orders with the selected status
    final Set<int> monthsWithOrdersForStatus = {};

    // Collect months that have orders with this status
    for (final order in _orderController.allOrders) {
      final orderStatus =
          (order.status.isEmpty) ? 'Non défini' : _formatStatus(order.status);

      if (orderStatus == selectedStatus) {
        monthsWithOrdersForStatus.add(order.createdAt.month);
      }
    }

    // Convert month numbers to month names and sort them
    final List<String> availableMonths = monthsWithOrdersForStatus
        .map((monthNum) => DateFormat('MMMM').format(DateTime(0, monthNum)))
        .toList()
      ..sort((a, b) => DateFormat('MMMM').parse(a).month.compareTo(
            DateFormat('MMMM').parse(b).month,
          ));

    // Handle case when no months have orders
    if (availableMonths.isEmpty) {
      return const Text('Aucune commande disponible');
    }

    // Set default month if current selection is not valid
    if (!availableMonths.contains(selectedMonth)) {
      selectedMonth = availableMonths.first;
    }

    return Row(
      children: [
        const Text('Mois: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedMonth,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedMonth = newValue;
              });
            }
          },
          items: availableMonths.map<DropdownMenuItem<String>>((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrdersListForStatusAndMonth() {
    final selectedMonthNumber = DateFormat('MMMM').parse(selectedMonth).month;

    // Filter orders by status and selected month
    final filteredOrders = _orderController.allOrders.where((order) {
      final orderStatus = (order.status == null || order.status.isEmpty)
          ? 'Non défini'
          : _formatStatus(order.status);

      return orderStatus == selectedStatus &&
          order.createdAt.month == selectedMonthNumber;
    }).toList();

    if (filteredOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Aucune commande pour ce statut ce mois-ci'),
      );
    }

    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text('Commande #${order.id}'),
              subtitle: Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}'),
              trailing: Text(
                '${order.total.toStringAsFixed(2)} TND',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, int> _prepareStatusData() {
    Map<String, int> data = {};

    // Récupérer tous les statuts possibles
    for (var order in _orderController.allOrders) {
      // Utiliser "Non défini" si le statut est vide ou null
      final status = (order.status == null || order.status.isEmpty)
          ? 'Non défini'
          : _formatStatus(order.status);

      data[status] = (data[status] ?? 0) + 1;
    }

    return data;
  }

  // Formatter le texte du statut pour l'affichage
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'Confirmée';
      case 'shipped':
        return 'En livraison';
      case 'delivered':
        return 'Completée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Non défini';
    }
  }

  List<PieChartSectionData> _getSections(Map<String, int> data) {
    final sections = <PieChartSectionData>[];
    final statusColors = _getStatusColors();
    final defaultColors = _getDefaultColors();
    int defaultColorIndex = 0;

    int index = 0;
    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 120 : 110;

      // Utiliser une couleur prédéfinie si disponible, sinon utiliser une couleur par défaut
      final color = statusColors[key] ??
          defaultColors[defaultColorIndex++ % defaultColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: value.toDouble(),
          title:
              '${(value / _orderController.allOrders.length * 100).toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
      index++;
    });

    return sections;
  }

  Map<String, Color> _getStatusColors() {
    return {
      'En attente': const Color(0xFFFFA726), // Orange
      'Confirmée': const Color(0xFF66BB6A), // Vert
      'En livraison': const Color(0xFF990099), // Violet
      'Completée': const Color(0xFF42A5F5), // Bleu
      'Annulée': const Color.fromARGB(255, 187, 19, 17), // Rouge
      'Non défini': const Color(0xFF9E9E9E), // Gris
    };
  }

  List<Color> _getDefaultColors() {
    return [
      const Color(0xFFFF9900),
      const Color(0xFF109618),
      const Color(0xFF990099),
      const Color(0xFF0099C6),
      const Color(0xFF3366CC),
      const Color(0xFFDC3912),
    ];
  }

  Widget _buildLegend(Map<String, int> data) {
    final statusColors = _getStatusColors();
    final defaultColors = _getDefaultColors();
    int defaultColorIndex = 0;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: data.entries.map((entry) {
        final statusLabel = entry.key;
        final count = entry.value;
        final percentage = (count / _orderController.allOrders.length * 100)
            .toStringAsFixed(1);

        final color = statusColors[statusLabel] ??
            defaultColors[defaultColorIndex++ % defaultColors.length];

        return GestureDetector(
          onTap: () => _toggleView(statusLabel),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$statusLabel ($count, ${percentage}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
