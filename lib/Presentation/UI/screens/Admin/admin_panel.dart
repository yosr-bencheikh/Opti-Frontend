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
import 'package:opti_app/Presentation/UI/screens/User/User_donut_chart.dart';

import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';

import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/data/data_sources/boutique_remote_datasource.dart';

import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/data/repositories/OrderRepositoryImpl.dart';
import 'package:opti_app/data/repositories/boutique_repository_impl.dart';

import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:opti_app/data/repositories/OpticianRepositoryImpl.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';

void main() {
  // Initialize controllers before app starts
// Register other dependencies
  final client = http.Client();
  Get.put<http.Client>(client); // Register UserDataSource and UserController
  final userDataSource = UserDataSourceImpl(
      client: client); // Assurez-vous que cette classe existe
  Get.put<UserDataSource>(userDataSource);
  final userController =
      UserController(userDataSource); // Initialisez UserController
  Get.put<UserController>(userController);
  final boutiqueRemoteDataSource = BoutiqueRemoteDataSourceImpl(client: client);
  Get.put<BoutiqueRemoteDataSource>(boutiqueRemoteDataSource);
final boutiqueRepository = BoutiqueRepositoryImpl(boutiqueRemoteDataSource);
  Get.put<BoutiqueRepository>(boutiqueRepository);
  final orderDataSource = OrderDataSourceImpl(client: client);
  Get.put<OrderDataSource>(orderDataSource);
  final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
  Get.put<OrderRepository>(orderRepository);
  Get.put<OrderController>(OrderController(
    orderRepository: orderRepository,
    boutiqueRepository: boutiqueRepository, // Add this line
  ));

  final opticienRemoteDataSource = OpticianDataSourceImpl();
  Get.put<OpticianDataSource>(opticienRemoteDataSource);
  final opticienRepository = OpticianRepositoryImpl(opticienRemoteDataSource);
  Get.put<OpticianRepository>(opticienRepository);
  Get.put<OpticianController>(OpticianController());



  Get.put<BoutiqueController>(
    BoutiqueController(
        boutiqueRepository: boutiqueRepository), // Correct parameter
  );

  final productRemoteDataSource = ProductDatasource();
  Get.put<ProductDatasource>(productRemoteDataSource);
  final productRepository =
      ProductRepositoryImpl(dataSource: productRemoteDataSource);
  Get.put<ProductRepository>(productRepository);
  Get.put<ProductRepositoryImpl>(productRepository);
  Get.put<ProductController>(
      ProductController(productRepository, productRemoteDataSource));

  runApp(
    GetMaterialApp(
      // Use GetMaterialApp instead of MaterialApp
      home: const AdminMainScreen(),
    ),
  );
}

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
    await Boutiquecontroller.getOpticien();
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

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
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
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LineChart(
            LineChartData(
              lineTouchData: const LineTouchData(enabled: true),
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
                        '${(value / 1000).toInt()}K',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
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