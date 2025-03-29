import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/domain/entities/Order.dart';

class MonthlyOpticianSalesChart extends StatefulWidget {
  const MonthlyOpticianSalesChart({Key? key}) : super(key: key);

  @override
  State<MonthlyOpticianSalesChart> createState() => _MonthlyOpticianSalesChartState();
}

class _MonthlyOpticianSalesChartState extends State<MonthlyOpticianSalesChart> {
  DateTime? selectedMonth;
  final _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.find<OrderController>();

    return Container(
      height: 380,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final availableMonths = 
                  _getAvailableMonths(orderController.allOrders);
              if (selectedMonth == null && availableMonths.isNotEmpty) {
                selectedMonth = availableMonths.first;
              }
              
              final monthlySales = _processMonthlySalesData(
                  orderController.allOrders);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights_rounded,
                              color: Colors.blueGrey[800], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Tendance des ventes mensuelles',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueGrey[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: monthlySales.isEmpty
                        ? _buildEmptyState()
                        : BarChart(
                            _buildMonthlySalesData(monthlySales),
                            key: _chartKey,
                          ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 60, color: Colors.blueGrey[200]),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée de vente disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _getAvailableMonths(List<Order> orders) {
    final Set<DateTime> months = {};
    for (final order in orders) {
      final orderDate = order.createdAt;
      final monthKey = DateTime(orderDate.year, orderDate.month, 1);
      months.add(monthKey);
    }
    final sortedMonths = months.toList()
      ..sort((a, b) => a.compareTo(b));
    return sortedMonths;
  }

  Map<DateTime, double> _processMonthlySalesData(List<Order> orders) {
    final Map<DateTime, double> monthlySales = {};

    // Filtrer uniquement les commandes complétées
    final completedOrders = orders.where((order) => 
        order.status == 'Completée').toList();

    for (final order in completedOrders) {
      final orderDate = order.createdAt;
      final monthKey = DateTime(orderDate.year, orderDate.month, 1);
      
      monthlySales.update(
        monthKey,
        (value) => value + order.total,
        ifAbsent: () => order.total,
      );
    }

    // Remplir les mois manquants avec 0
    if (monthlySales.isNotEmpty) {
      final firstMonth = monthlySales.keys.reduce(
          (a, b) => a.isBefore(b) ? a : b);
      final lastMonth = monthlySales.keys.reduce(
          (a, b) => a.isAfter(b) ? a : b);
      
      DateTime currentMonth = DateTime(firstMonth.year, firstMonth.month, 1);
      while (currentMonth.isBefore(lastMonth)) {
        monthlySales.putIfAbsent(currentMonth, () => 0);
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      }
    }

    final sortedEntries = monthlySales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sortedEntries);
  }

  BarChartData _buildMonthlySalesData(Map<DateTime, double> monthlySales) {
    final entriesList = monthlySales.entries.toList();
    final maxY = monthlySales.values.isEmpty ? 1000 : 
        monthlySales.values.reduce((max, value) => max > value ? max : value) * 1.2;

    return BarChartData(
      barTouchData: BarTouchData(
  enabled: true,
  touchTooltipData: BarTouchTooltipData(
    // Remove the tooltipBgColor parameter entirely
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      final month = entriesList[group.x.toInt()].key;
      return BarTooltipItem(
        '${DateFormat('MMM yyyy').format(month)}\n',
        const TextStyle(
          color: Colors.white,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '${NumberFormat.decimalPattern().format(rod.toY)} TND',
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      );
    },
  ),
),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < entriesList.length) {
                final month = entriesList[value.toInt()].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM').format(month),
                    style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${NumberFormat.compact().format(value)}',
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey[100]!, width: 1.5),
          left: BorderSide(color: Colors.blueGrey[100]!, width: 1.5),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 5).clamp(100, double.infinity),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.blueGrey[50]!,
          strokeWidth: 1.2,
        ),
      ),
      barGroups: entriesList.map((entry) {
        return BarChartGroupData(
          x: entriesList.indexOf(entry),
          barRods: [
            BarChartRodData(
              toY: entry.value,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5E8BAA),
                  const Color(0xFFA3C1D6),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
    );
  }
}