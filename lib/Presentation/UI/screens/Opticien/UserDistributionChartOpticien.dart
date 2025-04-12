import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/domain/entities/user.dart';

class UserDistributionChart extends StatefulWidget {
  const UserDistributionChart({Key? key}) : super(key: key);

  @override
  State<UserDistributionChart> createState() => _UserDistributionChartState();
}

class _UserDistributionChartState extends State<UserDistributionChart> with SingleTickerProviderStateMixin {
  final UserController _userController = Get.find<UserController>();
  final OrderController _orderController = Get.find<OrderController>();
  final OpticianController _opticianController = Get.find<OpticianController>();
  
  int touchedIndex = -1;
  String _selectedChartType = 'region';
  List<User> _users = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Palette de couleurs professionnelle
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

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _loadUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Méthode pour charger les utilisateurs une seule fois
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final users = await _loadOpticianUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des utilisateurs: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Méthode pour charger les utilisateurs ayant commandé des produits d'opticien
  Future<List<User>> _loadOpticianUsers() async {
    try {
      final opticianId = _opticianController.currentUserId.value;
      if (opticianId == null) {
        print("ID d'opticien non disponible");
        return [];
      }
      
      print("Chargement des utilisateurs pour l'opticien: $opticianId");
      final users = await _orderController.getUsersByOptician(opticianId);
      print("Utilisateurs chargés: ${users.length}");
      
      return users;
    } catch (e) {
      print("Erreur lors du chargement des utilisateurs: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getChartTitle(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4D69),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${_isLoading ? "..." : "${_users.length} clients"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                _buildChartTypeDropdown(),
              ],
            ),
            const SizedBox(height: 24),
            _buildChartContent(),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            if (!_isLoading) _buildLegend(_prepareChartData(_users)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF355C7D)),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement des données...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_users.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun client avec commandes trouvé',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 280,
          child: Stack(
            children: [
              PieChart(
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
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections: _getSections(_prepareChartData(_users), _users.length, _animation.value),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_users.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A4D69),
                      ),
                    ),
                    const Text(
                      'Clients',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C5B7B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _prepareChartData(List<User> users) {
    Map<String, int> data = {};

    switch (_selectedChartType) {
      case 'genre':
        for (var user in users) {
          final genre = user.genre.isEmpty ? 'Non spécifié' : user.genre;
          data[genre] = (data[genre] ?? 0) + 1;
        }
        break;
      case 'age':
        for (var user in users) {
          final age = _calculateAge(user.date);
          final ageGroup = _getAgeGroup(age);
          data[ageGroup] = (data[ageGroup] ?? 0) + 1;
        }
        break;
      case 'region':
        for (var user in users) {
          final region = user.region.isEmpty ? 'Non spécifié' : user.region;
          data[region] = (data[region] ?? 0) + 1;
        }
        break;
    }
    
    // Trier les données par valeur décroissante
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  List<PieChartSectionData> _getSections(Map<String, int> data, int totalUsers, double animationValue) {
    List<PieChartSectionData> sections = [];
    int index = 0;
    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 100 : 90;
      final color = _colorList[index % _colorList.length];
      
      // Calculer le pourcentage
      final percentage = (value / totalUsers * 100);
      final displayValue = percentage >= 3 ? '${percentage.toStringAsFixed(1)}%' : '';

      sections.add(PieChartSectionData(
        color: color,
        value: value.toDouble() * animationValue,
        title: displayValue,
        radius: radius * animationValue,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
        ),
        badgeWidget: isTouched ? _Badge(
  size: 40,
  borderColor: Colors.white,
  key: ValueKey(key), // Create a ValueKey from the string
  text: '${percentage.toStringAsFixed(1)}%',
) : null,
        badgePositionPercentageOffset: 1.1,
      ));
      index++;
    });
    return sections;
  }

  Widget _buildChartTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6C5B7B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChartType,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C5B7B)),
          isDense: true,
          hint: const Text('Type de répartition'),
          style: const TextStyle(
            color: Color(0xFF2A4D69),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedChartType) {
              setState(() {
                _selectedChartType = newValue;
                touchedIndex = -1; // Réinitialiser l'index touché lors du changement de vue
                _animationController.reset();
                _animationController.forward();
              });
            }
          },
          items: <String>['region', 'genre', 'age'].map((String value) {
            String label;
            switch (value) {
              case 'region':
                label = 'Par région';
                break;
              case 'genre':
                label = 'Par sexe';
                break;
              case 'age':
                label = 'Par âge';
                break;
              default:
                label = value;
            }
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    _getIconForChartType(value),
                    size: 16,
                    color: const Color(0xFF6C5B7B),
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getIconForChartType(String type) {
    switch (type) {
      case 'region':
        return Icons.location_on;
      case 'genre':
        return Icons.people;
      case 'age':
        return Icons.calendar_today;
      default:
        return Icons.pie_chart;
    }
  }

  String _getChartTitle() {
    switch (_selectedChartType) {
      case 'genre':
        return 'Répartition des Clients par Sexe';
      case 'age':
        return 'Répartition des Clients par Âge';
      case 'region':
        return 'Répartition des Clients par Région';
      default:
        return 'Répartition des Clients';
    }
  }

  int _calculateAge(String dateString) {
    if (dateString.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dateString);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _getAgeGroup(int age) {
    if (age <= 0) return 'Non spécifié';
    if (age < 18) return 'Moins de 18 ans';
    if (age < 25) return '18-24 ans';
    if (age < 35) return '25-34 ans';
    if (age < 45) return '35-44 ans';
    if (age < 55) return '45-54 ans';
    if (age < 65) return '55-64 ans';
    return '65 ans et plus';
  }

  Widget _buildLegend(Map<String, int> data) {
    List<Widget> legendItems = [];
    int index = 0;
    
    data.forEach((key, value) {
      final color = _colorList[index % _colorList.length];
      final percentage = (value / _users.length * 100).toStringAsFixed(1);
      
      legendItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
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
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    children: [
                      TextSpan(
                        text: key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' ($value · $percentage%)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    });

    return Wrap(
      spacing: 5,
      runSpacing: 3,
      alignment: WrapAlignment.start,
      children: legendItems,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge({
    required this.text,
    required this.size,
    required this.borderColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF2A4D69),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}