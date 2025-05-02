import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:opti_app/Presentation/UI/screens/Opticien/MonthlySalesChartOpticien.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OrderStatusChartOpticien.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/UserDistributionChartOpticien.dart';

import 'package:opti_app/Presentation/controllers/OpticianController.dart';

import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/user.dart';

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

  // In your dashboard widget's initState
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderController = Get.find<OrderController>();
      final opticianController = Get.find<OpticianController>();

      if (opticianController.isLoggedIn.value) {
        orderController.loadOrdersForCurrentOpticianWithDetails();
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    await userController.fetchUsers();
    await productController.loadProductsForCurrentOptician();
    await boutiqueController.getboutiqueByOpticianId(
        Get.find<OpticianController>().currentUserId.value);
    await orderController.loadOrdersForCurrentOpticianWithDetails();
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
                            OrderStatusChartOpticien(),
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
                            MonthlyOpticianSalesChart(),
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
    final opticianController = Get.find<OpticianController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bonjour, ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Obx(() => Text(
                      opticianController.opticianName.value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenue sur votre tableau de bord',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Date selector with elegant styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Color(0xFF3498DB)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
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

        // Get the optician controller
        final opticianController = Get.find<OpticianController>();

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
            // Define card properties
            String title;
            Color color;
            Color iconColor;
            Color backgroundColor;
            IconData icon;

            switch (index) {
              case 0: // Users
                title = 'Utilisateurs';
                color = Color(0xFFBBDEFB);
                iconColor = Color(0xFF64B5F6);
                backgroundColor = Color(0xFFE3F2FD);
                icon = Icons.people_rounded;
                break;
              case 1: // Products
                title = 'Produits';
                color = Color(0xFFE1BEE7);
                iconColor = Color(0xFFBA68C8);
                backgroundColor = Color(0xFFF3E5F5);
                icon = Icons.shopping_bag_rounded;
                break;
              case 2: // Boutiques
                title = 'Boutiques';
                color = Color(0xFFFFE0B2);
                iconColor = Color(0xFFFFB74D);
                backgroundColor = Color(0xFFFFF8E1);
                icon = Icons.store_rounded;
                break;
              case 3: // Orders
                title = 'Commandes';
                color = Color(0xFFC8E6C9);
                iconColor = Color(0xFF81C784);
                backgroundColor = Color(0xFFE8F5E9);
                icon = Icons.receipt_long_rounded;
                break;
              default:
                title = 'Unknown';
                color = Colors.grey;
                iconColor = Colors.grey.shade700;
                backgroundColor = Colors.grey.shade100;
                icon = Icons.error;
            }

            return Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
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
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
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
                              title,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildStatContent(
                                index,
                                opticianController.currentUserId.value,
                                userController,
                                productController,
                                boutiqueController,
                                orderController),
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

// Separate widget to handle the content of each stat card
Widget _buildStatContent(
    int index,
    String currentOpticianId,
    UserController userController,
    ProductController productController,
    BoutiqueController boutiqueController,
    OrderController orderController) {
  switch (index) {
    case 0: // Users
      return Obx(() {
        if (orderController.isloading) {
          return _buildStatValue("...");
        } else if (orderController.error.value != null) {
          return _buildStatValue("Erreur");
        } else {
          // Use cached users if available
          final cachedUsers = orderController.usersByOpticianCache[currentOpticianId];
          if (cachedUsers != null) {
            return _buildStatValue(cachedUsers.length.toString());
          }
          return FutureBuilder<List<User>>(
            future: orderController.getUsersByOptician(currentOpticianId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatValue("...");
              } else if (snapshot.hasError) {
                return _buildStatValue("Erreur");
              } else if (snapshot.hasData) {
                // Cache the result
                orderController.usersByOpticianCache[currentOpticianId] = snapshot.data!;
                return _buildStatValue(snapshot.data!.length.toString());
              } else {
                return _buildStatValue("0");
              }
            },
          );
        }
      });

      case 1: // Products
        // Use a more direct and simple approach with ObxValue
        return Obx(() {
          // Get boutique IDs
          final opticianBoutiqueIds = boutiqueController.opticiensList
              .where((b) => b.opticien_id == currentOpticianId)
              .map((b) => b.id)
              .toList();

          // Filter products
          final filteredProducts = productController.products
              .where((p) => opticianBoutiqueIds.contains(p.boutiqueId))
              .toList();

          // Check loading state using the getter method
          if (productController.isLoading) {
            return _buildStatValue("...");
          } else if (productController.error != null) {
            return _buildStatValue("Erreur");
          } else {
            return _buildStatValue(filteredProducts.length.toString());
          }
        });

      case 2: // Boutiques
        return Obx(() {
          final opticianBoutiques = boutiqueController.opticiensList
              .where((b) => b.opticien_id == currentOpticianId)
              .toList();

          // Correctly access the loading state based on your controller
          if (boutiqueController.isloading) {
            return _buildStatValue("...");
          } else {
            return _buildStatValue(opticianBoutiques.length.toString());
          }
        });

      case 3: // Orders
        return Obx(() {
          // Get boutique IDs
          final opticianBoutiqueIds = boutiqueController.opticiensList
              .where((b) => b.opticien_id == currentOpticianId)
              .map((b) => b.id)
              .toList();

          // Filter orders
          final filteredOrders = orderController.allOrders
              .where((order) => order.items
                  .any((item) => opticianBoutiqueIds.contains(item.boutiqueId)))
              .toList();

          // Correctly access the loading state based on your controller
          if (orderController.isloading) {
            return _buildStatValue("...");
          } else {
            return _buildStatValue(filteredOrders.length.toString());
          }
        });

      default:
        return _buildStatValue("0");
    }
  }

// Your existing _buildStatValue method
  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.black87,
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

    // Professional color palette (preserved from original)
    final List<Color> _colorList = const [
      Color(0xFF355C7D),
      Color(0xFF6C5B7B),
      Color(0xFFC06C84),
      Color(0xFFF67280),
      Color(0xFFF8B195),
      Color(0xFF4B86B4),
      Color(0xFF2A4D69),
      Color(0xFFADCBE3),
      Color(0xFF63A69F),
      Color(0xFFDE6E4B),
      Color(0xFF9DC8C8),
      Color(0xFF58C9B9),
      Color(0xFF519D9E),
      Color(0xFF1D4E89),
    ];

    // Get a color from the palette based on index (preserved from original)
    Color _getChartColor(int index) {
      return _colorList[index % _colorList.length];
    }

    // List of months (preserved from original)
    final List<String> months = List.generate(
        12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1)));

    // Observable for selected month (default current month) (preserved from original)
    final selectedMonth = DateFormat('MMMM').format(DateTime.now()).obs;

    // Observable for number of products to display (default: 5) (preserved from original)
    final selectedProductCount = 5.obs;

    // Adding animation progress as in the second file
    final animationProgress = 0.0.obs;

    // Start animation (from second file)
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

    // Build enhanced month dropdown (design from second file)
    Widget _buildEnhancedMonthDropdown() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF5F7A61).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedMonth.value,
            icon:
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5F7A61)),
            elevation: 16,
            isExpanded: true,
            style: const TextStyle(color: Color(0xFF2A4D69)),
            onChanged: (String? value) {
              if (value != null) {
                selectedMonth.value = value;
              }
            },
            items: months.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ),
      );
    }

    // Build product count dropdown (design from second file)
    Widget _buildProductCountDropdown(RxInt selectedCount) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF5F7A61).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedCount.value,
            icon: const Icon(Icons.unfold_more,
                color: Color(0xFF5F7A61), size: 18),
            elevation: 16,
            isExpanded: true,
            style: TextStyle(color: _colorList[0], fontWeight: FontWeight.w500),
            items: List.generate(
              10,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} produits'),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                selectedCount.value = value;
              }
            },
          ),
        ),
      );
    }

    // Build legend for the chart (updated design)
    Widget _buildLegend(List<MapEntry<String, int>> topProducts,
        ProductController productController) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 10,
          children: topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final productId = entry.value.key;
            final product = productController.products.firstWhere(
              (p) => p.id == productId,
              orElse: () => Product(
                  id: productId,
                  name: 'Unknown',
                  description: '',
                  category: '',
                  marque: '',
                  couleur: [],
                  prix: 0.0,
                  quantiteStock: 0,
                  materiel: '',
                  sexe: '',
                  averageRating: 0.0,
                  totalReviews: 0,
                  style: ''),
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getChartColor(index),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${product.name} (${entry.value.value})',
                  style: TextStyle(
                    fontSize: 12,
                    color: _colorList[6],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    return SizedBox(
      height: 600, // Height increased from 430 to 600 as in second file
      child: Obx(() {
        final selectedMonthNumber =
            DateFormat('MMMM').parse(selectedMonth.value).month;

        // Calculate product popularity for selected month (preserved from original)
        final Map<String, int> productPopularity = {};
        for (final order in orderController.allOrders) {
          // Only consider completed orders
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

        // Sort products by popularity and take top N (preserved from original)
        final sortedProducts = productPopularity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topProducts =
            sortedProducts.take(selectedProductCount.value).toList();

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart title with updated design
                const Text(
                  "Popularité des Produits",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5F7A61),
                  ),
                ),
                const SizedBox(height: 20),

                // Dropdowns with updated design
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
                const SizedBox(height: 24),

                // Chart (using the original bar chart logic with animation)
                Expanded(
                  child: topProducts.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune donnée disponible pour ce mois',
                            style:
                                TextStyle(color: _colorList[6], fontSize: 16),
                          ),
                        )
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
                                getTooltipColor: (BarChartGroupData group) =>
                                    _colorList[6].withOpacity(0.8),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(12),
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  if (groupIndex >= topProducts.length)
                                    return null;
                                  final productId = topProducts[groupIndex].key;
                                  final product =
                                      productController.products.firstWhere(
                                    (p) => p.id == productId,
                                    orElse: () => Product(
                                        id: productId,
                                        name: 'Unknown',
                                        description: '',
                                        category: '',
                                        marque: '',
                                        couleur: [],
                                        prix: 0.0,
                                        quantiteStock: 0,
                                        materiel: '',
                                        sexe: '',
                                        averageRating: 0.0,
                                        totalReviews: 0,
                                        style: ''),
                                  );
                                  return BarTooltipItem(
                                    '${product.name}\n',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Commandes: ${rod.toY.toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
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
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= topProducts.length)
                                      return const Text('');
                                    final productId = topProducts[index].key;
                                    final product =
                                        productController.products.firstWhere(
                                      (p) => p.id == productId,
                                      orElse: () => Product(
                                          id: productId,
                                          name: 'Unknown',
                                          description: '',
                                          category: '',
                                          marque: '',
                                          couleur: [],
                                          prix: 0.0,
                                          quantiteStock: 0,
                                          materiel: '',
                                          sexe: '',
                                          averageRating: 0.0,
                                          totalReviews: 0,
                                          style: ''),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: SideTitleWidget(
                                        angle: 0,
                                        space: 4,
                                        meta: meta,
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF5F7A61),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Quantité',
                                  style: TextStyle(
                                    color: _colorList[0],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                axisNameSize: 25,
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _colorList[6].withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: _colorList[7].withOpacity(0.3),
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: _colorList[7].withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
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
                                  color: _colorList[7].withOpacity(0.2),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                            barGroups: topProducts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final product = entry.value;
                              // Apply animation progress to bar height
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: product.value.toDouble() *
                                        animationProgress.value,
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        _getChartColor(index),
                                        _getChartColor(index).withOpacity(0.7),
                                      ],
                                    ),
                                    width: 28,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: (topProducts.isNotEmpty
                                              ? topProducts.first.value
                                                  .toDouble()
                                              : 100) *
                                          1.2,
                                      color: Colors.grey[100],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Legend with updated design
                _buildLegend(topProducts, productController),
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

class CustomSidebar extends StatefulWidget {
  final String currentPage;

  const CustomSidebar({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
      'label': 'Dashboard',
      'route': '/OpticienDashboard',
      'id': 'Dashboard',
    },
    {
      'icon': Icons.store_outlined,
      'activeIcon': Icons.store_rounded,
      'label': 'Boutiques',
      'route': '/Boutiques',
      'id': 'Boutiques',
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'activeIcon': Icons.shopping_bag_rounded,
      'label': 'Produits',
      'route': '/products',
      'id': 'Products',
    },
    {
      'icon': Icons.people_outline_rounded,
      'activeIcon': Icons.people_rounded,
      'label': 'Utilisateurs',
      'route': '/users',
      'id': 'Users',
    },
    {
      'icon': Icons.shopping_cart_outlined,
      'activeIcon': Icons.shopping_cart_rounded,
      'label': 'Commandes',
      'route': '/Commande',
      'id': 'Orders',
    },
  ];

  bool _isExpanded = true;
  bool _isHovering = false;

  void _navigateTo(BuildContext context, String routeName,
      {dynamic arguments}) {
    Get.offNamed(routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final OpticianController opticianController =
        Get.find<OpticianController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = Color(0xFF3CAEA3); // Accent color

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: _isExpanded ? 280 : 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 0),
            )
          ],
        ),
        child: Column(
          children: [
            // Logo and toggle button
            Container(
              height: 90,
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    secondaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: _isExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (_isExpanded)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.remove_red_eye,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "OptiVision",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(4), // Réduire le padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(8), // Réduire le rayon
                      ),
                      child: Icon(
                        Icons.remove_red_eye,
                        size: 20, // Réduire la taille de l'icône
                        color: primaryColor,
                      ),
                    ),
                  if (_isExpanded || _isHovering)
                    IconButton(
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(
                        _isExpanded ? Icons.menu_open : Icons.menu,
                        color: Colors.white,
                      ),
                      tooltip: _isExpanded ? 'Réduire' : 'Étendre',
                    ),
                ],
              ),
            ),

            // User profile
            AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 100,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 20 : 16, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: _isExpanded
                  ? Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    secondaryColor,
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.surface,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 26,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(() => Text(
                                    opticianController.opticianName.value,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              SizedBox(height: 2),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Opticien Principal",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _navigateTo(context, '/profile'),
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          tooltip: 'Paramètres',
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 24,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
            ),

            SizedBox(height: 20),

            // Main navigation
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
                  child: Column(
                    children: _menuItems.map((item) {
                      final bool isActive = widget.currentPage == item['id'];
                      return _buildMenuItem(
                        context: context,
                        icon: isActive ? item['activeIcon'] : item['icon'],
                        label: item['label'],
                        isActive: isActive,
                        onTap: () => _navigateTo(context, item['route']),
                        badge: item['badge'],
                        isExpanded: _isExpanded,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Bottom section with logout
            Container(
              padding:
                  EdgeInsets.all(_isExpanded ? 16 : 8), // Réduit le padding
              child: InkWell(
                onTap: () => opticianController.logout(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: _isExpanded ? 16 : 0,
                  ),
                  constraints: BoxConstraints(
                    minWidth: _isExpanded ? 280 : 80, // Contraintes de largeur
                    maxWidth: _isExpanded ? 280 : 80,
                  ),
                  child: Row(
                    mainAxisAlignment: _isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20, // Taille réduite
                        color: theme.colorScheme.error,
                      ),
                      if (_isExpanded) SizedBox(width: 12),
                      if (_isExpanded)
                        Flexible(
                          child: Text(
                            "Déconnexion",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14, // Taille réduite
                              color: theme.colorScheme.error,
                            ),
                            overflow: TextOverflow.ellipsis, // Ajouté
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isExpanded,
    int? badge,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              splashColor: isActive
                  ? Colors.white.withOpacity(0.1)
                  : primaryColor.withOpacity(0.05),
              highlightColor: isActive
                  ? Colors.white.withOpacity(0.05)
                  : primaryColor.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                    if (isExpanded) SizedBox(width: 14),
                    if (isExpanded)
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 15,
                            color: isActive
                                ? Colors.white
                                : theme.colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                      ),
                    if (isExpanded && badge != null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.25)
                              : primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.white,
                          ),
                        ),
                      )
                    else if (!isExpanded && badge != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            badge.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
