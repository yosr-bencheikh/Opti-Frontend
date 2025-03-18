import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:opti_app/Presentation/UI/screens/Admin/Monthly_sales_chart.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Order_Pie_Chart.dart';

import 'package:opti_app/Presentation/UI/screens/User/User_donut_chart.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';

import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';

// Dashboard screen
class OpticianDashboardScreen extends StatefulWidget {
  const OpticianDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OpticianDashboardScreen> createState() =>
      _OpticianDashboardScreenState();
}

class _OpticianDashboardScreenState extends State<OpticianDashboardScreen> {
  final UserController userController = Get.find<UserController>();
  final ProductController productController = Get.find<ProductController>();
  final BoutiqueController boutiqueController = Get.find<BoutiqueController>();
  final OrderController orderController = Get.find<OrderController>();
  final RxString selectedMonth = DateFormat('MMMM').format(DateTime.now()).obs;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch data when the screen is initialized
  }

  Future<void> _fetchData() async {
    await userController.fetchUsers();
    await productController.loadProducts();
    await boutiqueController.getOpticien();
    await orderController.loadAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar
          CustomSidebar(currentPage: 'Dashboard'), // Use CustomSidebar here

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              // Make the body scrollable
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildStatsGrid(userController, productController,
                      boutiqueController, orderController),
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
                      // Order Status Chart
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

                      // Monthly Sales Chart
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                                'Tendances des revenus mensuels'),
                            MonthlySalesChart(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tableau de bord',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Other header elements...
      ],
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
            mainAxisSpacing: 20,
            childAspectRatio: 2,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final stats = [
              {
                'title': 'Utilisateurs',
                'widget': Obx(() =>
                    _buildStatValue(userController.users.length.toString())),
                'color': const Color(0xFF7BACD4),
                'icon': Icons.people
              },
              {
                'title': 'Produits',
                'widget': Obx(() => _buildStatValue(
                    productController.products.length.toString())),
                'color': Colors.purple,
                'icon': Icons.shopping_bag
              },
              {
                'title': 'Boutiques',
                'widget': Obx(() => _buildStatValue(boutiqueController
                    .opticiensList.length
                    .toString())), // Dynamic value
                'color': Colors.orange,
                'icon': Icons.store
              },
              {
                'title': 'Commandes',
                'widget': Obx(() => _buildStatValue(
                      // Add Obx here
                      orderController.allOrders.length.toString(),
                    )),
                'color': Colors.green,
                'icon': Icons.receipt_long
              },
            ][index];
            return Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stats['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(stats['icon'] as IconData, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stats['title'] as String,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        stats['widget'] as Widget,
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final orderController = Get.find<OrderController>();

    return Obx(() {
      // Get unique months that have orders
      final Set<int> monthsWithOrders = {};

      // Collect months that have orders
      for (final order in orderController.allOrders) {
        monthsWithOrders.add(order.createdAt.month);
      }

      // Convert month numbers to month names and sort them
      final List<String> availableMonths = monthsWithOrders
          .map((monthNum) => DateFormat('MMMM').format(DateTime(0, monthNum)))
          .toList()
        ..sort((a, b) => DateFormat('MMMM').parse(a).month.compareTo(
              DateFormat('MMMM').parse(b).month,
            ));

      // Handle case when no months have orders
      if (availableMonths.isEmpty) {
        return const Text('No order data available');
      }

      // Set default month if current selection is not valid
      if (!availableMonths.contains(selectedMonth.value)) {
        selectedMonth.value = availableMonths.first;
      }

      return DropdownButton<String>(
        value: selectedMonth.value,
        onChanged: (String? newValue) {
          if (newValue != null) {
            selectedMonth.value = newValue;
          }
        },
        items: availableMonths.map<DropdownMenuItem<String>>((String month) {
          return DropdownMenuItem<String>(
            value: month,
            child: Text(month),
          );
        }).toList(),
      );
    });
  }

  Widget _buildProductsChart() {
    final orderController = Get.find<OrderController>();
    final productController = Get.find<ProductController>();

    // Liste des mois
    final List<String> months = List.generate(
        12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));

    // Observable pour le nombre de produits à afficher (valeur par défaut : 5)
    final selectedProductCount = 5.obs;

    return SizedBox(
      height: 430,
      child: Obx(() {
        final selectedMonthNumber =
            DateFormat('MMMM').parse(selectedMonth.value).month;

        // Calcul de la popularité des produits pour le mois sélectionné
        final Map<String, int> productPopularity = {};
        for (final order in orderController.allOrders) {
          // On ne considère que les commandes avec le statut "Completée"
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

        // Tri des produits par popularité décroissante et prise des N premiers produits
        final sortedProducts = productPopularity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topProducts =
            sortedProducts.take(selectedProductCount.value).toList();

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown pour sélectionner le mois
                _buildMonthDropdown(),
                const SizedBox(height: 20),
                // Dropdown pour sélectionner le nombre de produits à afficher
                Row(
                  children: [
                    const Text("Nombre de produits : "),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: selectedProductCount.value,
                      items: List.generate(
                        10,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          selectedProductCount.value = value;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (topProducts.isNotEmpty
                              ? topProducts.first.value.toDouble()
                              : 100) *
                          1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex >= topProducts.length) return null;
                            final productId = topProducts[groupIndex].key;
                            final product =
                                productController.products.firstWhere(
                              (p) => p.id == productId,
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
                        // Désactivation des titres en haut et à droite
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index >= topProducts.length)
                                return const Text('');
                              final productId = topProducts[index].key;
                              final product =
                                  productController.products.firstWhere(
                                (p) => p.id == productId,
                              );
                              return SideTitleWidget(
                                angle: 0,
                                space: 4,
                                meta: meta,
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
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
                                  color: Colors.grey,
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
                      ),
                      barGroups: topProducts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: product.value.toDouble(),
                              color: _getChartColor(index),
                              width: 28,
                              borderRadius: BorderRadius.circular(4),
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
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Helper function for chart colors
  Color _getChartColor(int index) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
    ];

    return colors[index % colors.length];
  }
}

// Navigation Drawer
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
    return Container(
      width: 250, // Fixed width for the drawer
      color: const Color.fromARGB(255, 113, 160, 201),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ...[
            'Dashboard',
            'Utilisateurs',
            'Opticiens',
            'Boutiques',
            'Produits',
            'Commandes',
          ].asMap().entries.map(
            (entry) {
              final index = entry.key;
              final title = entry.value;
              return ListTile(
                leading: Icon(
                  _getIcon(index),
                  color: selectedIndex == index ? Colors.white : Colors.white70,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color:
                        selectedIndex == index ? Colors.white : Colors.white70,
                    fontWeight: selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => onItemSelected(index),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.visibility_sharp;
      case 3:
        return Icons.store;
      case 4:
        return Icons.shopping_bag;
      case 5:
        return Icons.receipt_long;
      default:
        return Icons.error;
    }
  }
}

class CustomSidebar extends StatelessWidget {
  final String currentPage;

  const CustomSidebar({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OpticianController opticianController =
        Get.find<OpticianController>();
    return Container(
      width: 200,
      color: const Color(0xFFFEF1E9),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  child: const Center(),
                ),
                const SizedBox(width: 8),
                const Text(
                  "OptiVision",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Profile
          Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => Text(
                    opticianController.opticianName.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )),
              const Text(
                "Opticien Principal",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Navigation Menu
          _buildMenuItem(
              context,
              Icons.dashboard,
              "Dashboard",
              currentPage == 'Dashboard',
              () => _navigateTo(context, '/OpticienDashboard')),
          _buildMenuItem(
              context,
              Icons.shopping_bag,
              "Produits",
              currentPage == 'Products',
              () => _navigateTo(context, '/products')),
          _buildMenuItem(context, Icons.people, "Utilisateurs",
              currentPage == 'Users', () => _navigateTo(context, '/users')),
          _buildMenuItem(context, Icons.shopping_cart, "Commandes",
              currentPage == 'Orders', () => _navigateTo(context, '/Commande')),
          const Spacer(), // Pour pousser le bouton de déconnexion vers le bas
          // Bouton de déconnexion
          _buildMenuItem(
            context,
            Icons.logout,
            "Déconnexion",
            false,
            () => opticianController.logout(),
          ),
        ],
      ),
    );
  }

  // Helper function to navigate to a new screen
  void _navigateTo(BuildContext context, String routeName,
      {dynamic arguments}) {
    Get.offNamed(routeName, arguments: arguments);
  }

  // Menu item widget with navigation
  Widget _buildMenuItem(BuildContext context, IconData icon, String label,
      bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive ? Colors.white : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
