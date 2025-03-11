import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Commande.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Product_Screen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/UserScreen.dart';
import 'package:opti_app/Presentation/UI/screens/User/Monthly_sales_chart.dart';
import 'package:opti_app/Presentation/UI/screens/User/Order_Pie_Chart.dart';
import 'package:opti_app/Presentation/UI/screens/User/User_donut_chart.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

// Main app
class OpticianApp extends StatelessWidget {
  const OpticianApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OptiVision Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const OpticienDashboardScreen(),
    );
  }
}

// Dashboard screen
class OpticienDashboardScreen extends StatefulWidget {
  const OpticienDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OpticienDashboardScreen> createState() => _DashboardScreenState();
}

// Reusable sidebar component
class CustomSidebar extends StatelessWidget {
  final String currentPage;
  
  const CustomSidebar({
    Key? key,
    required this.currentPage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
       final OpticianController opticianController = Get.find<OpticianController>();
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
                    () => _navigateTo(context, '/OpticienDashboard')
                  ),
                          _buildMenuItem(
                    context, 
                    Icons.shopping_bag, 
                    "Produits", 
                    currentPage == 'Products',
                    () => _navigateTo(context, '/products') 
                  ),
          _buildMenuItem(
            context, 
            Icons.people, 
            "Utilisateurs", 
            currentPage == 'Users',
            () => _navigateTo(context, '/users')
          ),
          _buildMenuItem(
            context, 
            Icons.shopping_cart, 
            "Commandes", 
            currentPage == 'Orders',
            () => _navigateTo(context, '/Commande')
          ),
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
void _navigateTo(BuildContext context, String routeName, {dynamic arguments}) {
  Get.offNamed(routeName, arguments: arguments);
}

  // Menu item widget with navigation
  Widget _buildMenuItem(
    BuildContext context, 
    IconData icon, 
    String label, 
    bool isActive,
    VoidCallback onTap
  ) {
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

class _DashboardScreenState extends State<OpticienDashboardScreen> {
  final OpticianController opticianController = Get.find<OpticianController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar
          CustomSidebar(currentPage: 'Dashboard'),
          
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                           IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () {
                              opticianController.logout();
                            },
                            tooltip: 'Déconnexion',
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.notifications, color: Colors.red),
                                SizedBox(width: 5),
                                Text("3"),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.settings),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
              
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
                      const SizedBox(width: 20),
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
                  const SizedBox(height: 20),
                  // Channels
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
                  ),
      )],
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
Widget _buildProductsChart() {
    final orderController = Get.find<OrderController>();
    final productController = Get.find<ProductController>();

    return SizedBox(
      height: 380,
      child: Obx(() {
        // Calculate product popularity
        final Map<String, int> productPopularity = {};

        // Aggregate product orders
        for (final order in orderController.allOrders) {
          for (final item in order.items) {
            productPopularity.update(
              item.productId,
              (value) => value + item.quantity,
              ifAbsent: () => item.quantity,
            );
          }
        }

        // Get top 5 products
        final sortedProducts = productPopularity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final top5Products = sortedProducts.take(5).toList();

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (top5Products.isNotEmpty
                        ? top5Products.first.value.toDouble()
                        : 100) *
                    1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex >= top5Products.length) return null;

                      final productId = top5Products[groupIndex].key;
                      final product = productController.products.firstWhere(
                        (p) => p.id == productId,
                      );

                      return BarTooltipItem(
                        '${product.name}\nOrders: ${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= top5Products.length) return const Text('');

                        final productId = top5Products[index].key;
                        final product = productController.products.firstWhere(
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
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: top5Products.isNotEmpty
                      ? (top5Products.first.value ~/ 5).toDouble()
                      : 10,
                ),
                barGroups: top5Products.asMap().entries.map((entry) {
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

  Widget _buildProductItem(String name, String handle, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: const Icon(
              Icons.shopping_bag,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  handle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(String name, String percentage, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              percentage,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: percentage.contains("+") ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}