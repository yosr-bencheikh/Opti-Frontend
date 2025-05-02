import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Admin_Commande.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Admin_Opticiens.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/BoutiqueScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/ProductsScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/UsersScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Monthly_sales_chart.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Order_Pie_Chart.dart';
import 'package:opti_app/Presentation/UI/screens/User/Settings_screen.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/User_donut_chart.dart';

import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';

import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/data_sources/boutique_remote_datasource.dart';

import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/data/repositories/OrderRepositoryImpl.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:opti_app/data/repositories/boutique_repository_impl.dart';

import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:opti_app/data/repositories/OpticianRepositoryImpl.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0; // Track the selected navigation index
  final UserController userController = Get.find<UserController>();
  final ProductController productController = Get.find<ProductController>();
  final Boutiquecontroller = Get.find<BoutiqueController>();
  final OrderController orderController = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch data when the screen is initialized
  }

  Future<void> _fetchData() async {
    await userController.fetchUsers();
    await productController.loadProducts();
    await Boutiquecontroller.getboutique();
    await orderController.loadAllOrders();
  }

  final List<Widget> _screens = [
    AdminPanelApp(), // Dashboard
    const UsersScreen(),
    const OpticianScreen(),
    const BoutiqueScreen(),
    const ProductsScreen(),
    const AdminOrdersPage(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed Navigation Drawer
          NavigationDrawer(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          // Main content area
          Expanded(
            child: _screens[_selectedIndex], // Display the selected screen
          ),
        ],
      ),
    );
  }
}

class AdminPanelApp extends StatelessWidget {
  final RxString selectedMonth = DateFormat('MMMM').format(DateTime.now()).obs;
  final RxInt selectedMonthIndex = 0.obs;

  List<String> getMonths() {
    return List.generate(12, (index) {
      return DateFormat('MMMM').format(DateTime(0, index + 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    final ProductController productController = Get.find<ProductController>();
    final boutiqueController = Get.find<BoutiqueController>();
    final OrderController orderController = Get.find<OrderController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildStatsGrid(userController, productController, boutiqueController,
              orderController), // Pass controllers
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Popular Products Chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Top 5 Produits'),
                    _buildProductsChart(),
                  ],
                ),
              ),
              const SizedBox(width: 30),

              // User Repartition Chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Répartition des utilisateurs'),
                    UserDistributionChart(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Popular Products Chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Répartition des commandes'),
                    OrderStatusChart(),
                  ],
                ),
              ),
              const SizedBox(width: 30),

              // User Repartition Chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Tendances des revenus mensuels'),
                    MonthlySalesChart(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF3E5F5), // Pastel lavande très clair
            Color(0xFFE1F5FE), // Pastel bleu clair
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: Color(0xFF9FA8DA), // Indigo pastel
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(
                      0xFF5C6BC0), // Indigo plus foncé mais toujours pastel
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C6BC0), // Indigo pastel foncé
      ),
    );
  }

  Widget _buildStatsGrid(
      UserController userController,
      ProductController productController,
      BoutiqueController boutiqueController,
      OrderController orderController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 900
                ? 2
                : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 24,
            childAspectRatio: 2.2,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final stats = [
              {
                'title': 'Utilisateurs',
                'widget': Obx(() =>
                    _buildStatValue(userController.users.length.toString())),
                'color': Color(0xFFBBDEFB), // Bleu pastel
                'iconColor': Color(0xFF64B5F6), // Bleu pastel plus foncé
                'backgroundColor': Color(0xFFE3F2FD), // Bleu pastel très clair
                'icon': Icons.people_rounded
              },
              {
                'title': 'Produits',
                'widget': Obx(() => _buildStatValue(
                    productController.products.length.toString())),
                'color': Color(0xFFE1BEE7), // Violet pastel
                'iconColor': Color(0xFFBA68C8), // Violet pastel plus foncé
                'backgroundColor':
                    Color(0xFFF3E5F5), // Violet pastel très clair
                'icon': Icons.shopping_bag_rounded
              },
              {
                'title': 'Boutiques',
                'widget': Obx(() => _buildStatValue(
                    boutiqueController.opticiensList.length.toString())),
                'color': Color(0xFFFFE0B2), // Orange pastel
                'iconColor': Color(0xFFFFB74D), // Orange pastel plus foncé
                'backgroundColor':
                    Color(0xFFFFF8E1), // Orange pastel très clair
                'icon': Icons.store_rounded
              },
              {
                'title': 'Commandes',
                'widget': Obx(() => _buildStatValue(
                      orderController.allOrders.length.toString(),
                    )),
                'color': Color(0xFFC8E6C9), // Vert pastel
                'iconColor': Color(0xFF81C784), // Vert pastel plus foncé
                'backgroundColor': Color(0xFFE8F5E9), // Vert pastel très clair
                'icon': Icons.receipt_long_rounded
              },
            ][index];
            return Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: stats['backgroundColor'] as Color,
                  boxShadow: [
                    BoxShadow(
                      color: (stats['color'] as Color).withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stats['color'] as Color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (stats['color'] as Color).withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          stats['icon'] as IconData,
                          color: stats['iconColor'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stats['title'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            stats['widget'] as Widget,
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsChart() {
    final orderController = Get.find<OrderController>();
    final productController = Get.find<ProductController>();

    // Liste des mois
    final List<String> months = List.generate(
      12,
      (index) => DateFormat('MMMM').format(DateTime(0, index + 1)),
    );

    // Observables
    final selectedProductCount = 5.obs;
    final animationProgress = 0.0.obs;
    final chartType = "bar".obs;

    // Démarrage de l'animation
    Future.delayed(Duration.zero, () {
      animationProgress.value = 0.0;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (animationProgress.value < 1.0) {
          animationProgress.value += 0.05;
        } else {
          timer.cancel();
        }
      });
    });

    return SizedBox(
      height: 640,
      child: Obx(() {
        final selectedMonthNumber =
            DateFormat('MMMM').parse(selectedMonth.value).month;

        // Calcul de la popularité des produits
        final Map<String, int> productPopularity = {};
        for (final order in orderController.allOrders) {
          if (order.createdAt.month == selectedMonthNumber &&
              order.status == 'Completée') {
            for (final item in order.items) {
              productPopularity.update(
                item.productId,
                (value) => value + item.quantity,
                ifAbsent: () => item.quantity,
              );
            }
          }
        }

        // Tri des produits par popularité
        final sortedProducts = productPopularity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topProducts =
            sortedProducts.take(selectedProductCount.value).toList();

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et type de graphique
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Popularité des Produits",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F7A61),
                      ),
                    ),
                    _buildChartTypeSelector(chartType),
                  ],
                ),
                const SizedBox(height: 20),

                // Dropdowns
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: _buildEnhancedMonthDropdown(),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 160,
                      child: _buildProductCountDropdown(selectedProductCount),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Graphique
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: chartType.value == "bar"
                        ? _buildBarChart(
                            topProducts,
                            productController,
                            animationProgress.value,
                          )
                        : _buildPieChart(
                            topProducts,
                            productController,
                            animationProgress.value,
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Légende
                _buildLegend(topProducts, productController),
              ],
            ),
          ),
        );
      }),
    );
  }

// Version optimisée des dropdowns pour l'affichage en ligne
  Widget _buildEnhancedMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 18, color: Color(0xFF5F7A61)),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => DropdownButton<String>(
                  isExpanded: true,
                  value: selectedMonth.value,
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF5F7A61)),
                  style: TextStyle(color: Color(0xFF3A3845), fontSize: 14),
                  onChanged: (value) {
                    if (value != null) {
                      selectedMonth.value = value;
                    }
                  },
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: DateFormat('MMMM').format(DateTime(0, index + 1)),
                      child: Text(
                        DateFormat('MMMM').format(DateTime(0, index + 1)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCountDropdown(Rx<int> selectedProductCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_numbered, size: 18, color: Color(0xFF5F7A61)),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => DropdownButton<int>(
                  isExpanded: true,
                  value: selectedProductCount.value,
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF5F7A61)),
                  style: TextStyle(color: Color(0xFF3A3845), fontSize: 14),
                  onChanged: (value) {
                    if (value != null) {
                      selectedProductCount.value = value;
                    }
                  },
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1} produits'),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

Widget _buildChartTypeSelector(Rx<String> chartType) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bar_chart, color: Color(0xFF2D4263), size: 20),
        SizedBox(width: 8),
        Text(
          "Barres",
          style: TextStyle(
            color: Color(0xFF2D4263),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildBarChart(
    List<MapEntry<String, int>> topProducts,
    ProductController productController,
    double animationProgress,
  ) {
    return topProducts.isEmpty
        ? const Center(child: Text("Aucune donnée disponible pour ce mois"))
        : BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (topProducts.isNotEmpty
                      ? topProducts.first.value.toDouble()
                      : 100) *
                  1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      const Color(0xFF2D4263).withOpacity(0.8),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex >= topProducts.length) return null;
                    final productId = topProducts[groupIndex].key;
                    final product = productController.products.firstWhere(
                      (p) => p.id == productId,
                      orElse: () => Product(
                          id: '',
                          name: 'Inconnu',
                          description: '',
                          category: '',
                          marque: '',
                          couleur: [],
                          prix: 0,
                          quantiteStock: 0,
                          materiel: '',
                          sexe: '',
                          averageRating: 0,
                          totalReviews: 0,
                          style: ''),
                    );
                    return BarTooltipItem(
                      '${product.name}\nCommandes : ${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= topProducts.length) return const Text('');
                      final productId = topProducts[index].key;
                      final product = productController.products.firstWhere(
                        (p) => p.id == productId,
                        orElse: () => Product(
                            id: '',
                            name: 'Inconnu',
                            description: '',
                            category: '',
                            marque: '',
                            couleur: [],
                            prix: 0,
                            quantiteStock: 0,
                            materiel: '',
                            sexe: '',
                            averageRating: 0,
                            totalReviews: 0,
                            style: ''),
                      );
                      return SideTitleWidget(
                        angle: 0,
                        space: 4,
                        meta: meta,
                        child: Text(
                          product.name.length > 10
                              ? '${product.name.substring(0, 10)}...'
                              : product.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3A3845),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3A3845),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: topProducts.isNotEmpty
                    ? ((topProducts.first.value ~/ 5)
                        .toDouble()
                        .clamp(1, double.infinity))
                    : 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              barGroups: topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: product.value.toDouble() * animationProgress,
                      color: _getPastelColor(index),
                      width: 28,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: double.infinity,
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
  }

  Widget _buildPieChart(List<MapEntry<String, int>> topProducts,
      ProductController productController, double animationProgress) {
    if (topProducts.isEmpty) {
      return Center(child: Text("Aucune donnée disponible pour ce mois"));
    }

    // Calculer la somme totale
    final totalValue =
        topProducts.fold(0, (sum, product) => sum + product.value);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          enabled: true,
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final productId = product.key;
          final productObj = productController.products.firstWhere(
            (p) => p.id == productId,
          );

          // Calculer le pourcentage
          final percentage = (product.value / totalValue) * 100;

          return PieChartSectionData(
            color: _getPastelColor(index),
            value: product.value.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 120 * animationProgress,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            badgeWidget: percentage >= 5
                ? _PieBadge(
                    productName: productObj.name,
                    size: 20,
                    borderColor: Colors.white,
                  )
                : null,
            badgePositionPercentageOffset: 0.9,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> topProducts,
      ProductController productController) {
    // filter out any IDs we don’t actually have
    final validLegend = topProducts
        .where(
            (entry) => productController.products.any((p) => p.id == entry.key))
        .toList();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: validLegend.length,
        itemBuilder: (context, index) {
          final productId = validLegend[index].key;
          // safe to use firstWhere now
          final product =
              productController.products.firstWhere((p) => p.id == productId);

          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _getPastelColor(index),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Color(0xFF3A3845),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPastelColor(int index) {
    final colors = [
      Color(0xFFB5DEFF), // Bleu pastel
      Color(0xFFFFB6B9), // Rose pastel
      Color(0xFFBBDED6), // Vert menthe pastel
      Color(0xFFFAE0D8), // Pêche pastel
      Color(0xFFE2E2F0), // Lavande pastel
      Color(0xFFFFF0AA), // Jaune pastel
      Color(0xFFCBC3E3), // Violet pastel
      Color(0xFFAFDDCC), // Vert d'eau pastel
      Color(0xFFF9C0C0), // Corail pastel
      Color(0xFFCFE5CF) // Vert sauge pastel
    ];
    return colors[index % colors.length];
  }

  String _getProductName(double x) {
    switch (x.toInt()) {
      case 0:
        return 'Smartphone X';
      case 1:
        return 'Laptop Pro';
      case 2:
        return 'Headphones XL';
      case 3:
        return 'Smartwatch';
      case 4:
        return 'Tablet Mini';
      default:
        return '';
    }
  }

  String _getShopName(double x) {
    switch (x.toInt()) {
      case 0:
        return 'TechWorld';
      case 1:
        return 'Fashion Hub';
      case 2:
        return 'HomeGoods';
      case 3:
        return 'SportCenter';
      case 4:
        return 'BeautyZone';
      default:
        return '';
    }
  }

  Widget _buildRevenueChart() {
    return Column(
      children: [
        SizedBox(
          height: 600,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      if (touchResponse != null &&
                          touchResponse.lineBarSpots != null &&
                          touchResponse.lineBarSpots!.isNotEmpty) {
                        final spotIndex =
                            touchResponse.lineBarSpots![0].spotIndex;
                        selectedMonthIndex.value = spotIndex.toInt();
                      }
                    },
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            _getMonth(value),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '\$${(value / 1000).toInt()}K',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 20000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 8000),
                        FlSpot(1, 12000),
                        FlSpot(2, 9500),
                        FlSpot(3, 14000),
                        FlSpot(4, 16500),
                        FlSpot(5, 19000),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.3),
                            Colors.green.withOpacity(0.3)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Details Card
        Obx(() => _buildDetailsCard(selectedMonthIndex.value)),
      ],
    );
  }

  String _getMonth(double x) {
    switch (x.toInt()) {
      case 0:
        return 'Jan';
      case 1:
        return 'Feb';
      case 2:
        return 'Mar';
      case 3:
        return 'Apr';
      case 4:
        return 'May';
      case 5:
        return 'Jun';
      default:
        return '';
    }
  }

  Widget _buildDetailsCard(int selectedMonthIndex) {
    final monthlyRevenues = [
      8000.0,
      12000.0,
      9500.0,
      14000.0,
      16500.0,
      19000.0,
    ];

    final currentMonthRevenue = monthlyRevenues[selectedMonthIndex];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenu du mois de ${_getMonth(selectedMonthIndex.toDouble())}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${(currentMonthRevenue / 1000).toStringAsFixed(1)}K',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Détails du revenu',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenu total: \$${(currentMonthRevenue / 1000).toStringAsFixed(1)}K',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Mois: ${_getMonth(selectedMonthIndex.toDouble())}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      _buildPieSection(35, Colors.green),
                      _buildPieSection(25, Colors.orange),
                      _buildPieSection(20, const Color(0xFF7BACD4)),
                      _buildPieSection(10, Colors.red),
                      _buildPieSection(10, Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _LegendItem('Delivered', Colors.green),
                    _LegendItem('Processing', Colors.orange),
                    _LegendItem('Shipped', Color(0xFF7BACD4)),
                    _LegendItem('Cancelled', Colors.red),
                    _LegendItem('Returned', Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}%',
      radius: 80,
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Palette de couleurs pastel élégantes
    final Color softLavender = Color.fromARGB(255, 86, 129, 221);
    final Color paleBlue = Color(0xFFB8CDE5);
    final Color mintGreen = Color(0xFFCEE5D0);
    final Color blushPink = Color(0xFFF3D7DA);
    final Color creamyBeige = Color(0xFFF5EFE0);
    final Color dustyRose = Color(0xFFE8BBBA);
    final Color lightGrey = Color(0xFFF0F2F5);
    final Color textDark = Color.fromARGB(255, 43, 44, 44);
    final Color accentGold = Color.fromARGB(255, 190, 135, 16);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [softLavender, paleBlue],
          stops: [0.1, 0.9],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section avec un design élégant
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: accentGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.12), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Logo avec effet de brillance subtil
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent
                        ],
                        radius: 1.2,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentGold,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 0,
                        )
                      ]),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: accentGold,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Titre élégant
                Text(
                  'ESPACE ADMIN',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                    wordSpacing: 3.0,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Divider élégant
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentGold.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentGold, accentGold.withOpacity(0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Category Label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Row(
              children: [
                Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: textDark.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: accentGold.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              physics: BouncingScrollPhysics(),
              children: [
                _buildMenuItem(
                    0,
                    'Tableau de bord',
                    Icons.dashboard_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    blushPink),
                _buildMenuItem(
                    1,
                    'Utilisateurs',
                    Icons.people_alt_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    mintGreen),
                _buildMenuItem(
                    2,
                    'Opticiens',
                    Icons.visibility_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    dustyRose),
                _buildMenuItem(
                    3,
                    'Boutiques',
                    Icons.store_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    blushPink),
                _buildMenuItem(
                    4,
                    'Produits',
                    Icons.inventory_2_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    mintGreen),
                _buildMenuItem(
                    5,
                    'Commandes',
                    Icons.shopping_bag_rounded,
                    selectedIndex,
                    onItemSelected,
                    paleBlue,
                    textDark,
                    accentGold,
                    dustyRose),
              ],
            ),
          ),

          // Footer Section avec badge de statut et profil élégant
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: accentGold.withOpacity(0.15),
                  width: 1,
                ),
              ),
              color: Colors.white.withOpacity(0.08),
            ),
            child: Row(
              children: [
                // Avatar avec bordure élégante
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentGold.withOpacity(0.7),
                        width: 1.5,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          accentGold.withOpacity(0.1),
                          Colors.transparent
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        )
                      ]),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.person_rounded,
                    color: accentGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // User info avec design élégant
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                                color: Color.fromARGB(
                                    255, 48, 183, 104), // Vert pastel de statut
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF6FCF97).withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  )
                                ]),
                          ),
                          Text(
                            'Administrateur',
                            style: TextStyle(
                              color: textDark.withOpacity(0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper function pour créer un élément de menu élégant
  Widget _buildMenuItem(
      int index,
      String title,
      IconData icon,
      int selectedIndex,
      Function(int) onItemSelected,
      Color paleBlue,
      Color textDark,
      Color accentGold,
      Color accentColor) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white : Colors.transparent,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? accentColor.withOpacity(0.1)
                      : Colors.transparent,
                  blurRadius: 4,
                  spreadRadius: 0,
                )
              ]),
          child: Icon(
            icon,
            color: isSelected ? accentColor : textDark.withOpacity(0.7),
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? textDark : textDark.withOpacity(0.75),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            : null,
        onTap: () => onItemSelected(index),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.people_alt_rounded;
      case 2:
        return Icons.visibility_rounded;
      case 3:
        return Icons.store_rounded;
      case 4:
        return Icons.inventory_2_rounded;
      case 5:
        return Icons.shopping_bag_rounded;
      case 6:
        return Icons.bar_chart_rounded;
      case 7:
        return Icons.insights_rounded;
      case 8:
        return Icons.settings_rounded;
      case 9:
        return Icons.notifications_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final Color color;

  const _LegendItem(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PieBadge extends StatelessWidget {
  final String productName;
  final double size;
  final Color borderColor;

  const _PieBadge({
    required this.productName,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          productName.isNotEmpty ? productName[0].toUpperCase() : '',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A3845),
          ),
        ),
      ),
    );
  }
}
