import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Commande.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Product_Screen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/UserScreen.dart';

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
              const Text(
                "Martin Dupont",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                      // Activity
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Activité",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text("01-07 Mars"),
                                        const SizedBox(width: 5),
                                        const Icon(Icons.arrow_drop_down, size: 15),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            String text = '';
                                            if (value == 0) {
                                              text = '0';
                                            } else if (value == 10) {
                                              text = '10';
                                            } else if (value == 20) {
                                              text = '20';
                                            } else if (value == 30) {
                                              text = '30';
                                            } else if (value == 40) {
                                              text = '40';
                                            }
                                            return Text(
                                              text,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            String text = '';
                                            if (value == 1) {
                                              text = '01';
                                            } else if (value == 2) {
                                              text = '02';
                                            } else if (value == 3) {
                                              text = '03';
                                            } else if (value == 4) {
                                              text = '04';
                                            } else if (value == 5) {
                                              text = '05';
                                            } else if (value == 6) {
                                              text = '06';
                                            } else if (value == 7) {
                                              text = '07';
                                            }
                                            return Text(
                                              text,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          const FlSpot(1, 20),
                                          const FlSpot(2, 35),
                                          const FlSpot(3, 25),
                                          const FlSpot(4, 15),
                                          const FlSpot(5, 30),
                                          const FlSpot(6, 25),
                                          const FlSpot(7, 32),
                                        ],
                                        isCurved: true,
                                        color: Colors.orange,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            if (index == 5) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: Colors.orange,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
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
                                          color: Colors.orange.withOpacity(0.2),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                          return touchedBarSpots.map((barSpot) {
                                            return LineTooltipItem(
                                              '${barSpot.y.toInt()} clients',
                                              const TextStyle(color: Colors.black),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Top Performers
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Produits populaires",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildProductItem("Lunettes Ray-Ban", "@rayban", "39%"),
                              _buildProductItem("Lentilles Acuvue", "@acuvue", "25%"),
                              _buildProductItem("Oakley Sport", "@oakley", "18%"),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => ProductsScreen()),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Text("Voir Plus"),
                                    const SizedBox(width: 5),
                                    const Icon(Icons.arrow_forward, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Channels
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sources de clients",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Statistiques pour la période de 1 semaine",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildChannelCard("Référence médicale", "+5%", Colors.pink),
                            const SizedBox(width: 15),
                            _buildChannelCard("Site web", "-2%", Colors.blue),
                            const SizedBox(width: 15),
                            _buildChannelCard("Publicité", "+4%", Colors.deepOrange),
                            const SizedBox(width: 15),
                            _buildChannelCard("Renouvellement", "+3%", Colors.red),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Stats\nComplètes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
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