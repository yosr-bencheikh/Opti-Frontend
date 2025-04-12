import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class UserDistributionChart extends StatefulWidget {
  const UserDistributionChart({Key? key}) : super(key: key);

  @override
  State<UserDistributionChart> createState() => _UserDistributionChartState();
}

class _UserDistributionChartState extends State<UserDistributionChart>
    with SingleTickerProviderStateMixin {
  final UserController _userController = Get.find<UserController>();
  int touchedIndex = -1;
  String _selectedChartType = 'region'; // Par défaut: répartition par région
  bool _isDonut = true; // Toggle entre donut et bar chart
  bool _showPercentage = true; // Toggle pour afficher les pourcentages

  // Contrôleur pour l'animation de rotation
  late AnimationController _animationController;

  // Palette de couleurs pastel professionnelles
  final List<Color> _pastelColors = const [
    Color(0xFFB5D8F7), // Bleu ciel pastel
    Color(0xFFD7BDE2), // Lavande pastel
    Color(0xFFA8E6CE), // Menthe pastel
    Color(0xFFFFD3B5), // Pêche pastel
    Color(0xFFFFAAC9), // Rose pastel
    Color(0xFFA2D2FF), // Bleu azur pastel
    Color(0xFFFFDAD6), // Corail pastel
    Color(0xFFBDE0FE), // Bleu poudre pastel
    Color(0xFFC1E1C1), // Vert sage pastel
    Color(0xFFFFC8A2), // Orange pastel
    Color(0xFFFDFDBA), // Jaune pastel
    Color(0xFFCFBAF0), // Violet pastel
    Color(0xFFB0F2B4), // Vert menthe pastel
    Color(0xFFF9C0C0), // Rose saumon pastel
  ];

  // Couleurs pour le thème global
  final Color _backgroundColor = const Color(0xFFF8F9FD);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF596780);
  final Color _accentColor = const Color(0xFF7B8794);
  final Color _dropdownColor = const Color(0xFFF0F4F9);
  final Color _shadowColor = const Color(0xFFE0E7FF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Lancer l'animation initiale après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_userController.isLoading) {
        return Center(
          child: CircularProgressIndicator(
            color: _pastelColors[0],
            strokeWidth: 3,
          ),
        );
      }
      if (_userController.error != null) {
        return Center(
          child: Text(
            'Erreur: ${_userController.error}',
            style: GoogleFonts.poppins(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      if (_userController.users.isEmpty) {
        return Center(
          child: Text(
            'Aucune donnée disponible',
            style: GoogleFonts.poppins(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      final chartData = _prepareChartData();
      final chartTitle = _getChartTitle();

      return Card(
        elevation: 8,
        shadowColor: _shadowColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: _cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et contrôles supérieurs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _pastelColors[0],
                              _pastelColors[3],
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideX(
                          begin: -50,
                          duration: 500.ms,
                          curve: Curves.easeOutQuad),
                      const SizedBox(width: 12),
                      Text(
                        chartTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          letterSpacing: 0.3,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideX(
                          begin: -30,
                          duration: 500.ms,
                          curve: Curves.easeOutQuad),
                    ],
                  ),
                  Row(
                    children: [
                      _buildViewToggle(),
                      const SizedBox(width: 10),
                      _buildChartTypeDropdown(),
                    ],
                  ).animate().fadeIn(duration: 800.ms).slideY(
                      begin: -20, duration: 500.ms, curve: Curves.easeOutQuad),
                ],
              ),
              const SizedBox(height: 5),
              // Sous-titre
              Text(
                'Analyse détaillée de ${_userController.users.length} utilisateurs',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(duration: 800.ms).slideX(
                  begin: -20, duration: 600.ms, curve: Curves.easeOutQuad),

              Divider(
                color: _textColor.withOpacity(0.1),
                height: 30,
              ),

              // Chart Section
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isDonut
                    ? _buildDonutChart(chartData)
                    : _buildBarChart(chartData),
              ),

              const SizedBox(height: 10),

              // Options supplémentaires
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPercentageToggle(),
                    _buildAnimateButton(),
                  ],
                ),
              ).animate().fadeIn(duration: 1000.ms).slideY(
                  begin: 20, duration: 600.ms, curve: Curves.easeOutQuad),

              const SizedBox(height: 16),

              // Légende avec design professionnel
              _buildLegend(chartData),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 800.ms)
  .scale(begin: const Offset(0.95, 0.95), duration: 800.ms, curve: Curves.easeOutQuint);
    });
  }

  Widget _buildDonutChart(Map<String, int> chartData) {
    return SizedBox(
      height: 290,
      key: const ValueKey('donut'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * math.pi * 0.05,
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
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    startDegreeOffset: 270,
                    sections: _getSections(chartData),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeInOutQuart,
                ),
              );
            },
          ),
          // Centre du donut avec animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 110 + (_animationController.value * 10),
                height: 110 + (_animationController.value * 10),
                decoration: BoxDecoration(
                  color: _cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor
                          .withOpacity(0.2 * _animationController.value),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_userController.users.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    Text(
                      'Utilisateurs',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> chartData) {
    // Pour l'histogramme, nous limitons à 8 entrées maximum pour une meilleure lisibilité
    final limitedData = Map.fromEntries(
      chartData.entries.take(8),
    );

    final double maxValue = limitedData.values
        .reduce((max, value) => value > max ? value : max)
        .toDouble();
    final double interval = (maxValue / 5).ceilToDouble();

    return SizedBox(
      height: 290,
      key: const ValueKey('bar'),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: 20),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue + (interval * 0.5),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => _textColor.withOpacity(0.8),
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final entry = limitedData.entries.elementAt(groupIndex);
                  final percentage =
                      (entry.value / _userController.users.length * 100)
                          .toStringAsFixed(1);
                  return BarTooltipItem(
                    '${entry.key}\n',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '${entry.value} ',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '($percentage%)',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                });
              },
            ),
titlesData: FlTitlesData(
  show: true,
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 60,
      getTitlesWidget: (double value, TitleMeta meta) {
        if (value >= limitedData.length || value < 0) return const SizedBox();
        final name = limitedData.keys.elementAt(value.toInt());
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Transform.rotate(
            angle: 0.3,
            child: Text(
              name.length > 10 ? '${name.substring(0, 8)}...' : name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
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
        if (value == 0) return const SizedBox();
        return Text(
          value.toInt().toString(),
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: _textColor.withOpacity(0.6),
          ),
        );
      },
      interval: interval,
    ),
  ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % interval == 0,
              getDrawingHorizontalLine: (value) => FlLine(
                color: _textColor.withOpacity(0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: false,
            ),
            // Création de l'histogramme avec animation
            barGroups: List.generate(limitedData.length, (index) {
              final entry = limitedData.entries.elementAt(index);
              final isTouched = index == touchedIndex;
              final double y = entry.value.toDouble();

              final double width = isTouched ? 22 : 18;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: y * _animationController.value,
                    color: _pastelColors[index % _pastelColors.length],
                    width: width,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue,
                      color: _pastelColors[index % _pastelColors.length]
                          .withOpacity(0.1),
                    ),
                  ),
                ],
                showingTooltipIndicators: isTouched ? [0] : [],
              );
            }),
          ),
          swapAnimationDuration: const Duration(milliseconds: 800),
          swapAnimationCurve: Curves.easeInOutQuart,
        ),
      ),
    );
  }

  Widget _buildChartTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _dropdownColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChartType,
          icon: Icon(Icons.keyboard_arrow_down, color: _accentColor),
          isDense: true,
          style: GoogleFonts.poppins(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedChartType = newValue;
                touchedIndex = -1;
                _resetAnimation();
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

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _dropdownColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton donut
          InkWell(
            onTap: () {
              if (!_isDonut) {
                setState(() {
                  _isDonut = true;
                  _resetAnimation();
                });
              }
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isDonut
                    ? _pastelColors[0].withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.pie_chart,
                size: 18,
                color: _isDonut ? _textColor : _textColor.withOpacity(0.6),
              ),
            ),
          ),
          // Bouton histogramme
          InkWell(
            onTap: () {
              if (_isDonut) {
                setState(() {
                  _isDonut = false;
                  _resetAnimation();
                });
              }
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !_isDonut
                    ? _pastelColors[0].withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.bar_chart,
                size: 18,
                color: !_isDonut ? _textColor : _textColor.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showPercentage = !_showPercentage;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _dropdownColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showPercentage ? Icons.percent : Icons.numbers,
              size: 16,
              color: _pastelColors[1],
            ),
            const SizedBox(width: 6),
            Text(
              _showPercentage ? "Afficher valeurs" : "Afficher %",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimateButton() {
    return GestureDetector(
      onTap: _resetAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _dropdownColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: _pastelColors[2],
            ),
            const SizedBox(width: 6),
            Text(
              "Animer",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ],
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
        // Trier les tranches d'âge dans l'ordre logique
        final sortedData = <String, int>{};
        final ageOrder = [
          'Non spécifié',
          'Moins de 18 ans',
          '18-24 ans',
          '25-34 ans',
          '35-44 ans',
          '45-54 ans',
          '55-64 ans',
          '65 ans et plus'
        ];
        for (var ageGroup in ageOrder) {
          if (data.containsKey(ageGroup)) {
            sortedData[ageGroup] = data[ageGroup]!;
          }
        }
        data = sortedData;
        break;
      case 'region':
        // Données par région
        for (var user in _userController.users) {
          final region = user.region.isEmpty ? 'Non spécifié' : user.region;
          data[region] = (data[region] ?? 0) + 1;
        }
        // Trier par nombre d'utilisateurs
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        data = Map.fromEntries(sortedEntries);
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
      final double fontSize = isTouched ? 16 : 14;
      final double radius = isTouched ? 115 : 100;
      final color = _pastelColors[index % _pastelColors.length];
      final percentage = value / _userController.users.length * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: value.toDouble(),
          title: _showPercentage
              ? '${percentage.toStringAsFixed(1)}%'
              : value.toString(),
          radius: radius,
          titleStyle: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: _textColor.withOpacity(0.9),
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          badgeWidget: isTouched
              ? _Badge(
                  svgAsset: 'assets/icons/chart_icon.svg',
                  size: 40,
                  borderColor: color,
                  // Fallback si l'asset n'est pas disponible
                  fallbackWidget: Icon(Icons.info, color: _textColor, size: 16),
                )
              : null,
          badgePositionPercentageOffset: 1.1,
          borderSide: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      );
      index++;
    });
    return sections;
  }

  Widget _buildLegend(Map<String, int> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                Text(
                  'Total: ${_userController.users.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Legend items with smooth animation
          AnimatedList(
            initialItemCount: data.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              final entry = data.entries.elementAt(index);
              final percentage =
                  (entry.value / _userController.users.length * 100)
                      .toStringAsFixed(1);

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: index == touchedIndex
                            ? _pastelColors[index % _pastelColors.length]
                                .withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _pastelColors[index % _pastelColors.length],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    _pastelColors[index % _pastelColors.length]
                                        .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textColor,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.value.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($percentage%)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: const VisualDensity(vertical: -2),
                        onTap: () {
                          setState(() {
                            touchedIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String svgAsset;
  final double size;
  final Color borderColor;
  final Widget? fallbackWidget;

  const _Badge({
    required this.svgAsset,
    required this.size,
    required this.borderColor,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: fallbackWidget ?? const Icon(Icons.info, size: 16),
      ),
    );
  }
}
