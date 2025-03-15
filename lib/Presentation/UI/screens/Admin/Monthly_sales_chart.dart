import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/domain/entities/Order.dart';

class MonthlySalesChart extends StatefulWidget {
  const MonthlySalesChart({Key? key}) : super(key: key);

  @override
  State<MonthlySalesChart> createState() => _MonthlySalesChartState();
}

class _MonthlySalesChartState extends State<MonthlySalesChart> {
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
              final dailySales = _processDailySalesData(
                  orderController.allOrders, selectedMonth!);

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
                            'Ventes mensuelles de lunettes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueGrey[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      _MonthSelectorDropdown(
                        availableMonths: availableMonths,
                        selectedMonth: selectedMonth,
                        onChanged: (month) =>
                            setState(() => selectedMonth = month),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: dailySales.isEmpty
                        ? _buildEmptyState()
                        : LineChart(
                            _buildDailySalesData(dailySales),
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
            'No sales data available\nfor selected month',
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
    final sortedMonths = months.toList()..sort();
    return sortedMonths;
  }

  Map<DateTime, double> _processDailySalesData(
      List<Order> orders, DateTime month) {
    final Map<DateTime, double> dailySales = {};
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    // Filter orders by type "Completée"
    final filteredOrders = orders.where((order) {
      return order.status == 'Completée';
    }).toList();

    for (final order in filteredOrders) {
      final orderDate = order.createdAt;
      if (orderDate.isAfter(month.subtract(const Duration(seconds: 1))) &&
          orderDate.isBefore(nextMonth)) {
        final dayKey = DateTime(orderDate.year, orderDate.month, orderDate.day);
        double orderTotal =
            order.items.fold(0, (sum, item) => sum + item.totalPrice);
        dailySales.update(
          dayKey,
          (value) => value + orderTotal,
          ifAbsent: () => orderTotal,
        );
      }
    }

    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      final dayKey = DateTime(month.year, month.month, i);
      dailySales.putIfAbsent(dayKey, () => 0);
    }

    final sortedEntries = dailySales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sortedEntries);
  }

  LineChartData _buildDailySalesData(Map<DateTime, double> dailySales) {
    if (dailySales.isEmpty) {
      return LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    final entriesList = dailySales.entries.toList();
    final spots = List.generate(entriesList.length, (index) {
      return FlSpot(index.toDouble(), entriesList[index].value);
    });

    // Calculate maxY based on the daily sales values
    final maxY = dailySales.values.isEmpty
        ? 10.0
        : dailySales.values.reduce((max, value) => max > value ? max : value) *
            1.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 5).clamp(1, double.infinity),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.blueGrey[50]!,
          strokeWidth: 1.2,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < entriesList.length) {
                final date = entriesList[value.toInt()].key;
                if (date.day % 5 == 0 || date.day == entriesList.last.key.day) {
                  return Transform.rotate(
                    angle: -0.4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
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
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
              color: const Color.fromARGB(255, 220, 213, 207)!, width: 1.5),
          left: BorderSide(color: Colors.blueGrey[100]!, width: 1.5),
        ),
      ),
      minX: 0,
      maxX: (entriesList.length - 1).toDouble(),
      minY: 0, // Ensure minY is set to 0
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.blueGrey[800]!,
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final date = entriesList[touchedSpot.x.toInt()].key;
              return LineTooltipItem(
                '${DateFormat('EEE, MMM d').format(date)}\n',
                const TextStyle(
                  color: Colors.white,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text:
                        '${NumberFormat.decimalPattern().format(touchedSpot.y)} TND',
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0,
          color: const Color.fromARGB(255, 236, 139, 14),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 235, 126, 164),
              const Color.fromARGB(255, 65, 157, 203).withOpacity(0.6)
            ],
          ),
          barWidth: 4,
          shadow: const Shadow(color: Colors.black12, blurRadius: 8),
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              if (spot.y > 0) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _Colors.chartLine,
                );
              }
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _Colors.chartArea.withOpacity(0.4),
                _Colors.chartArea.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSelectorDropdown extends StatelessWidget {
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final Function(DateTime?) onChanged;

  const _MonthSelectorDropdown({
    required this.availableMonths,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<DateTime>(
        value: selectedMonth,
        onChanged: onChanged,
        items: availableMonths.map((month) {
          return DropdownMenuItem<DateTime>(
            value: month,
            child: Text(
              DateFormat('MMM yyyy').format(month),
              style: TextStyle(
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.blueGrey[600]),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
      ),
    );
  }
}

// Define the _Colors class
class _Colors {
  static const chartLine =
      Color(0xFF5E8BAA); // Example color for the chart line
  static const chartArea =
      Color(0xFFA3C1D6); // Example color for the chart area
}
