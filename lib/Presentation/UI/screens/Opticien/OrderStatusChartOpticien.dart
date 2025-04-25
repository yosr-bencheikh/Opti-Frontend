import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';

class OrderStatusChartOpticien extends StatefulWidget {
  const OrderStatusChartOpticien({Key? key}) : super(key: key);

  @override
  State<OrderStatusChartOpticien> createState() =>
      _OrderStatusChartOpticienState();
}

class _OrderStatusChartOpticienState extends State<OrderStatusChartOpticien>
    with SingleTickerProviderStateMixin {
  final OrderController _orderController = Get.find<OrderController>();
  int touchedIndex = -1;
  String? selectedStatus;
  String selectedMonth = '';
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _rotationAnimation;
  bool showDetailView = false;
  bool showExportOptions = false;
  DateTime? startDate;
  DateTime? endDate;

  final Map<String, Color> statusColors = {
    'En attente': const Color(0xFFA0C4FF), // Bleu pastel
    'Confirmée': const Color(0xFFFFC6FF), // Lavande pastel
    'En livraison': const Color(0xFF9BF6FF), // Cyan pastel
    'Completée': const Color(0xFFA0E7BA), // Vert menthe pastel
    'Annulée': const Color(0xFFFFDAD6), // Saumon pastel
    'Non défini': const Color(0xFFE7E7E7), // Gris pâle
  };

  final List<Color> defaultColors = [
    const Color(0xFFFFC6FF),
    const Color(0xFFFFDEB4),
    const Color(0xFFCDEAC0),
    const Color(0xFFB5DEFF),
    const Color(0xFFE2D8FF),
    const Color(0xFFF0E6D3),
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    selectedMonth = DateFormat('MMMM').format(DateTime.now());
    endDate = DateTime.now();
    startDate = endDate!.subtract(const Duration(days: 30));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleView(String status) {
    // Complete any ongoing animation first
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    setState(() {
      touchedIndex = -1; // Reset touched index

      if (selectedStatus == status && showDetailView) {
        showDetailView = false;
        selectedStatus = null;
        _animationController.reverse();
      } else {
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
        return _buildShimmerLoading();
      }

      if (_orderController.allOrders.isEmpty) {
        return _buildEmptyState();
      }

      return Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _buildHeader(),
              if (!showDetailView) _buildDateRangeSelector(),
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

  Widget _buildShimmerLoading() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                height: 30,
                width: 200,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: statusColors['En attente']!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande disponible',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les données des commandes de votre boutique s\'afficheront ici',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6C757D).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Titre centré
        Center(
          child: Text(
            showDetailView
                ? 'Commandes ${selectedStatus ?? ""}'
                : 'Votre Activité',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Bouton retour à gauche
        if (showDetailView)
          Positioned(
            left: 0,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: statusColors[selectedStatus ?? 'En attente'],
                      size: 24,
                    ),
                    onPressed: () => _toggleView(selectedStatus!),
                  ),
                );
              },
            ),
          ),
        // Espace fictif à droite pour équilibrer
        if (showDetailView)
          const Positioned(
            right: 0,
            child: SizedBox(width: 48), // même largeur que IconButton environ
          ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showExportOptions ? 120 : 50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 18, color: Color(0xFF6C757D)),
                    const SizedBox(width: 8),
                    Text(
                      'Période:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildDatePill('7 jours', () {
                      setState(() {
                        endDate = DateTime.now();
                        startDate =
                            DateTime.now().subtract(const Duration(days: 7));
                      });
                    }),
                    _buildDatePill('30 jours', () {
                      setState(() {
                        endDate = DateTime.now();
                        startDate =
                            DateTime.now().subtract(const Duration(days: 30));
                      });
                    }),
                    _buildDatePill('Perso.', () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: statusColors['Confirmée']!,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: const Color(0xFF2C3E50),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked.start;
                          endDate = picked.end;
                        });
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Ensure we complete all ongoing animations before state changes
        if (_animationController.isAnimating) {
          _animationController.stop();
        }

        // Add this to reset touched index
        touchedIndex = -1;

        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6C757D),
            )),
      ),
    );
  }

  Widget _buildOverviewChart() {
    final statusData = _prepareStatusData();

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              Center(
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
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
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
                    sectionsSpace: 3,
                    centerSpaceRadius:
                        0, // Changed from 60 to 0 to make it a full pie chart
                    sections: _getSections(statusData),
                    startDegreeOffset: 180,
                  ),
                ),
              ),
              // Removed the center container that was displaying the total count
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildLegend(statusData),
        const SizedBox(height: 8),
        // Adding the total count as a separate element below the chart
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6C757D),
                ),
              ),
              Text(
                _orderController.allOrders.length.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(
                ' commandes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
        _buildSummaryMetrics(statusData),
      ],
    );
  }

  Widget _buildSummaryMetrics(Map<String, int> data) {
    final totalOrders = _orderController.allOrders.length;
    final completedOrders = data['Completée'] ?? 0;
    final completionRate =
        totalOrders > 0 ? completedOrders / totalOrders * 100 : 0;
    final double totalRevenue =
        _orderController.allOrders.fold(0, (sum, order) => sum + order.total);
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF8F9FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCard(
            'Taux de succès',
            '${completionRate.toStringAsFixed(1)}%',
            Icons.check_circle_outline_rounded,
            statusColors['Completée']!,
          ),
          _buildMetricCard(
            'Revenu total',
            '${totalRevenue.toStringAsFixed(2)} TND',
            Icons.payments_rounded,
            statusColors['Confirmée']!,
          ),
          _buildMetricCard(
            'Panier moyen',
            '${avgOrderValue.toStringAsFixed(2)} TND',
            Icons.shopping_bag_outlined,
            statusColors['En livraison']!,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            )),
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6C757D),
            )),
      ],
    );
  }

  Widget _buildDetailView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMonthDropdownForStatus(),
        const SizedBox(height: 20),
        SizedBox(
          height: 350,
          child: _buildOrdersChartForStatusAndMonth(),
        ),
      ],
    );
  }

  Widget _buildOrdersChartForStatusAndMonth() {
    final filteredOrders = _orderController.allOrders.where((order) {
      final orderStatus =
          (order.status.isEmpty) ? 'Non défini' : _formatStatus(order.status);
      final selectedMonthNumber = DateFormat('MMMM').parse(selectedMonth).month;
      return orderStatus == selectedStatus &&
          order.createdAt.month == selectedMonthNumber;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: statusColors[selectedStatus]!.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              selectedMonth == 'Tous'
                  ? 'Aucune commande pour ce statut'
                  : 'Aucune commande ce mois-ci',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      );
    }

    final double totalRevenue =
        filteredOrders.fold(0, (sum, order) => sum + order.total);
    filteredOrders.sort((a, b) => b.total.compareTo(a.total));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRevenueCard(filteredOrders, totalRevenue),
        const SizedBox(height: 16),
        Text(
          'Répartition des commandes (${filteredOrders.length})',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final dateString = DateFormat('dd/MM/yy').format(order.createdAt);
              final orderTotal = order.total;
              final fractionOfTotal =
                  totalRevenue > 0 ? orderTotal / totalRevenue : 0.0;

              return _buildOrderItem(
                  order, dateString, orderTotal, fractionOfTotal);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRevenueCard(
      List<dynamic> filteredOrders, double totalRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColors[selectedStatus!]!.withOpacity(0.1),
            statusColors[selectedStatus!]!.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insert_chart_outlined_rounded,
                      size: 18, color: statusColors[selectedStatus!]),
                  const SizedBox(width: 8),
                  Text('Analyse des revenus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColors[selectedStatus!],
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Text('${totalRevenue.toStringAsFixed(2)} TND',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  )),
              Text('Total des revenus',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6C757D),
                  )),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${filteredOrders.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      )),
                  Text('Commandes',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6C757D),
                      )),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getStatusIcon(selectedStatus!),
                  size: 24,
                  color: statusColors[selectedStatus!],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'En attente':
        return Icons.hourglass_empty_rounded;
      case 'Confirmée':
        return Icons.thumb_up_alt_rounded;
      case 'En livraison':
        return Icons.local_shipping_rounded;
      case 'Completée':
        return Icons.check_circle_rounded;
      case 'Annulée':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildOrderItem(dynamic order, String dateString, double orderTotal,
      double fractionOfTotal) {
    final Color baseColor = statusColors[selectedStatus!] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_bag_outlined,
                        size: 16, color: baseColor),
                  ),
                  const SizedBox(width: 8),
                  Text('CMD-${order.id}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF2C3E50),
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: Color(0xFF6C757D)),
                    const SizedBox(width: 4),
                    Text(dateString,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6C757D),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fillWidth = fractionOfTotal * totalWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: totalWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              baseColor.withOpacity(0.6),
                              baseColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: baseColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(fractionOfTotal * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: baseColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: baseColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${orderTotal.toStringAsFixed(2)} TND',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: baseColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdownForStatus() {
    final Set<int> monthsWithOrders = {};

    for (final order in _orderController.allOrders) {
      final orderStatus =
          (order.status.isEmpty) ? 'Non défini' : _formatStatus(order.status);
      if (orderStatus == selectedStatus) {
        monthsWithOrders.add(order.createdAt.month);
      }
    }

    // Add this safety check
    if (monthsWithOrders.isEmpty) {
      // If no orders for this status, add current month
      monthsWithOrders.add(DateTime.now().month);
    }

    final List<String> availableMonths = monthsWithOrders
        .map((month) => DateFormat('MMMM').format(DateTime(0, month)))
        .toList()
      ..sort((a, b) => DateFormat('MMMM').parse(a).month.compareTo(
            DateFormat('MMMM').parse(b).month,
          ));

    // Safety check to ensure there's always at least one month
    if (availableMonths.isEmpty) {
      availableMonths.add(DateFormat('MMMM').format(DateTime.now()));
    }

    // Make sure selectedMonth is valid
    if (!availableMonths.contains(selectedMonth)) {
      selectedMonth = availableMonths.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 20, color: statusColors[selectedStatus!]),
              const SizedBox(width: 8),
              Text(
                'Filtrer par mois:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: const Color(0xFF2C3E50),
                ),
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: DropdownButton<String>(
              value: selectedMonth,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: statusColors[selectedStatus!]),
              underline: const SizedBox(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C3E50),
              ),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => selectedMonth = newValue);
              },
              items:
                  availableMonths.map<DropdownMenuItem<String>>((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _prepareStatusData() {
    Map<String, int> data = {};

    final filteredOrders = _orderController.allOrders.where((order) {
      if (startDate == null || endDate == null) return true;
      return order.createdAt.isAfter(startDate!) &&
          order.createdAt.isBefore(endDate!.add(const Duration(days: 1)));
    }).toList();

    // Safety check - if no orders match the filter
    if (filteredOrders.isEmpty) {
      // Add a placeholder status
      data['Non défini'] = 0;
      return data;
    }

    for (var order in filteredOrders) {
      final status =
          (order.status.isEmpty) ? 'Non défini' : _formatStatus(order.status);
      data[status] = (data[status] ?? 0) + 1;
    }

    return data;
  }

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
    int defaultColorIndex = 0;

    data.forEach((key, value) {
      final isTouched = sections.length == touchedIndex;
      final radius = isTouched ? 130.0 : 110.0;

      final color = statusColors[key] ??
          defaultColors[defaultColorIndex++ % defaultColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: value.toDouble(),
          title:
              '${(value / _orderController.allOrders.length * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    });

    return sections;
  }

  Widget _buildLegend(Map<String, int> data) {
    int defaultColorIndex = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: data.entries.map((entry) {
          final statusLabel = entry.key;
          final count = entry.value;
          final percentage = (count / _orderController.allOrders.length * 100)
              .toStringAsFixed(1);
          final color = statusColors[statusLabel] ??
              defaultColors[defaultColorIndex++ % defaultColors.length];

          return GestureDetector(
            onTap: () => _toggleView(statusLabel),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '$count ($percentage%)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: color.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
