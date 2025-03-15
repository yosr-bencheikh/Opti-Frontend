import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';

class OrderStatusChart extends StatefulWidget {
  const OrderStatusChart({Key? key}) : super(key: key);

  @override
  State<OrderStatusChart> createState() => _OrderStatusChartState();
}

class _OrderStatusChartState extends State<OrderStatusChart> {
  final OrderController _orderController = Get.find<OrderController>();
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_orderController.allOrders.isEmpty) {
        return const Center(child: Text('Aucune commande disponible'));
      }

      // Préparer les données pour le graphique
      final statusData = _prepareStatusData();

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pie chart
              SizedBox(
                height: 310, // Increased height for the pie chart
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
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0, // No space between sections
                    centerSpaceRadius: 0, // No hole in the center (pie chart)
                    sections: _getSections(statusData),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegend(statusData), // Legend with all colors
            ],
          ),
        ),
      );
    });
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

    // Couleurs pour différents statuts
    final statusColors = {
      'En attente': const Color(0xFFFFA726), // Orange
      'Confirmée': const Color(0xFF66BB6A), // Bleu
      'En livraison': const Color(0xFF990099), // Vert
      'Completée': const Color(0xFF42A5F5), // Vert-bleu
      'Annulée': const Color.fromARGB(255, 187, 19, 17), // Rouge
      'Non défini': const Color(0xFF9E9E9E),
      // Gris
    };

    // Couleurs par défaut pour d'autres statuts non prédéfinis
    final defaultColors = [
      const Color(0xFFFF9900),
      const Color(0xFF109618),
      const Color(0xFF990099),
      const Color(0xFF0099C6),
      const Color(0xFF3366CC),
      const Color(0xFFDC3912),
    ];

    int defaultColorIndex = 0;

    int index = 0;
    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius =
          isTouched ? 120 : 110; // Increased radius for bigger chart

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

  Widget _buildLegend(Map<String, int> data) {
    // Couleurs pour différents statuts
    final statusColors = {
      'En attente': const Color(0xFFFFA726), // Orange
      'Confirmée': const Color(0xFF66BB6A), // Bleu
      'En livraison': const Color(0xFF990099), // Vert
      'Completée': const Color(0xFF42A5F5), // Vert-bleu
      'Annulée': const Color.fromARGB(255, 187, 19, 17), // Rouge
      'Non défini': const Color(0xFF9E9E9E),
      // Gris
    };

    // Couleurs par défaut pour d'autres statuts non prédéfinis
    final defaultColors = [
      const Color(0xFFFF9900),
      const Color(0xFF109618),
      const Color(0xFF990099),
      const Color(0xFF0099C6),
      const Color(0xFF3366CC),
      const Color(0xFFDC3912),
    ];

    int defaultColorIndex = 0;

    return Wrap(
      spacing: 10, // Espacement horizontal entre les éléments
      runSpacing: 10, // Espacement vertical entre les lignes
      children: data.entries.map((entry) {
        final statusLabel = entry.key;
        final count = entry.value;
        final percentage = (count / _orderController.allOrders.length * 100)
            .toStringAsFixed(1);

        // Utiliser une couleur prédéfinie si disponible, sinon utiliser une couleur par défaut
        final color = statusColors[statusLabel] ??
            defaultColors[defaultColorIndex++ % defaultColors.length];

        return Row(
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
        );
      }).toList(),
    );
  }
}
