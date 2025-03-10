import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';

class UserDistributionChart extends StatefulWidget {
  const UserDistributionChart({Key? key}) : super(key: key);

  @override
  State<UserDistributionChart> createState() => _UserDistributionChartState();
}

class _UserDistributionChartState extends State<UserDistributionChart> {
  final UserController _userController = Get.find<UserController>();
  int touchedIndex = -1;
  String _selectedChartType = 'region'; // Par défaut: répartition par sexe

  // Liste de couleurs partagée entre le PieChart et la légende
  final List<Color> _colorList = const [
    Color(0xFFDD4477),
    Color(0xFFFF9900),
    Color(0xFF0099C6),
    Color(0xFF109618),
    Color(0xFFB82E2E),
    Color(0xFF990099),
    Color(0xFF3366CC),
    Color(0xFFFF9900),
    Color(0xFF990099),
    Color(0xFF3366CC),
    Color(0xFFDC3912),
    Color(0xFFFF9900),
    Color(0xFF66AA00),
    Color(0xFF316395),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_userController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_userController.error != null) {
        return Center(child: Text('Erreur: ${_userController.error}'));
      }
      if (_userController.users.isEmpty) {
        return const Center(child: Text('Aucune donnée disponible'));
      }

      final chartData = _prepareChartData();
      final chartTitle = _getChartTitle();

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Ligne de titre et dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    chartTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  _buildChartTypeDropdown(),
                ],
              ),
              const SizedBox(height: 16),
              // Donut chart
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
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
                        centerSpaceRadius: 50,
                        sections: _getSections(chartData),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${_userController.users.length}\nUtilisateurs',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Légende avec Wrap pour une gestion automatique des retours à la ligne
              _buildLegend(chartData),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildChartTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChartType,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          isDense: true,
          hint: const Text('Type de répartition'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedChartType = newValue;
              });
            }
          },
          items: <String>['genre', 'age', 'region'].map((String value) {
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
              child: Text(label),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedChartType) {
      case 'genre':
        return 'Répartition par Sexe';
      case 'age':
        return 'Répartition par Âge';
      case 'region':
        return 'Répartition par Région';
      default:
        return 'Répartition des Utilisateurs';
    }
  }

  Map<String, int> _prepareChartData() {
    Map<String, int> data = {};

    switch (_selectedChartType) {
      case 'genre':
        // Données par genre
        for (var user in _userController.users) {
          final genre = user.genre.isEmpty ? 'Non spécifié' : user.genre;
          data[genre] = (data[genre] ?? 0) + 1;
        }
        break;
      case 'age':
        // Données par tranche d'âge
        for (var user in _userController.users) {
          final age = _calculateAge(user.date);
          final ageGroup = _getAgeGroup(age);
          data[ageGroup] = (data[ageGroup] ?? 0) + 1;
        }
        break;
      case 'region':
        // Données par région
        for (var user in _userController.users) {
          final region = user.region.isEmpty ? 'Non spécifié' : user.region;
          data[region] = (data[region] ?? 0) + 1;
        }
        break;
    }
    return data;
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

  List<PieChartSectionData> _getSections(Map<String, int> data) {
    List<PieChartSectionData> sections = [];
    int index = 0;
    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 90 : 80;
      final color = _colorList[index % _colorList.length];

      sections.add(PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title:
            '${(value / _userController.users.length * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ));
      index++;
    });
    return sections;
  }

  Widget _buildLegend(Map<String, int> data) {
    // On crée une liste d'éléments pour la légende
    List<Widget> legendItems = [];
    int index = 0;
    data.forEach((key, value) {
      final color = _colorList[index % _colorList.length];
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                '$key ($value)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
      index++;
    });

    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: legendItems,
    );
  }
}
