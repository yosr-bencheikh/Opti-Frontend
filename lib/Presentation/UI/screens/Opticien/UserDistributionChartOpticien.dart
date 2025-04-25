import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/User_donut_chart.dart';
import 'package:opti_app/domain/entities/user.dart';
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
  final OrderController _orderController = Get.find<OrderController>();
  final OpticianController _opticianController = Get.find<OpticianController>();

  int touchedIndex = -1;
  String _selectedChartType = 'region';
  List<User> _users = [];
  bool _isLoading = true;
  bool _isDonut = true; // Toggle entre donut et bar chart
  bool _showPercentage = true; // Toggle pour afficher les pourcentages

  late AnimationController _animationController;
  late Animation<double> _animation;

  // Palette de couleurs professionnelle
  final List<Color> _colorList = const [
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
    Color(0xFFF9C0C0),
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

    // Configuration de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );
    if (_isAnimating) {
      _resetAnimation(); // Démarre l'animation automatiquement à l'initialisation
    }

    _loadUsers();

    // Lancer l'animation initiale après un court délai
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _resetAnimation() {
    _animationController.reset();
    _animationController.repeat(reverse: false); // fait un aller-retour
  }

  // Méthode pour charger les utilisateurs une seule fois

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
    final chartData = _prepareChartData(_users);
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
                            _colorList[0],
                            _colorList[3],
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      chartTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildViewToggle(),
                    const SizedBox(width: 10),
                    _buildChartTypeDropdown(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Sous-titre
            Text(
              _isLoading
                  ? 'Chargement...'
                  : 'Analyse détaillée de ${_users.length} clients',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textColor.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),

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
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _isDonut
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
            ),

            const SizedBox(height: 16),

            // Légende avec design professionnel
            if (!_isLoading) _buildLegend(chartData),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_colorList[0]),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des données...',
              style: GoogleFonts.poppins(
                color: _textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
                angle: _animationController.value * 2 * math.pi,
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
                      '${_users.length}',
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
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value >= limitedData.length || value < 0)
                      return const SizedBox();
                    final name = limitedData.keys.elementAt(value.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Text(
                          name.length > 10
                              ? '${name.substring(0, 8)}...'
                              : name,
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
            // Création de l'histogramme sans animation
            barGroups: List.generate(limitedData.length, (index) {
              final entry = limitedData.entries.elementAt(index);
              final isTouched = index == touchedIndex;
              final double y = entry.value.toDouble();

              final double width = isTouched ? 22 : 18;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY:
                        y, // Suppression de l'animation, on passe directement y
                    color: _colorList[index % _colorList.length],
                    width: width,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue,
                      color: _colorList[index % _colorList.length]
                          .withOpacity(0.1),
                    ),
                  ),
                ],
                showingTooltipIndicators: isTouched ? [0] : [],
              );
            }),
          ),
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
                    ? _colorList[0].withOpacity(0.5)
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
                    ? _colorList[0].withOpacity(0.5)
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
              color: _colorList[1],
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

  bool _isAnimating = true;

  Widget _buildAnimateButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAnimating = !_isAnimating;
          if (_isAnimating) {
            _resetAnimation(); // démarre l’animation
          } else {
            _animationController.stop(); // arrête l’animation
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isAnimating ? Colors.greenAccent.shade100 : _dropdownColor,
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
              _isAnimating ? Icons.check_circle : Icons.refresh,
              size: 16,
              color: _isAnimating ? Colors.green : _colorList[2],
            ),
            const SizedBox(width: 6),
            Text(
              _isAnimating ? "Animé" : "Animer",
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

  Widget _buildAnimateToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: _isAnimating,
          activeColor: Colors.green,
          onChanged: (value) {
            setState(() {
              _isAnimating = value;
              if (_isAnimating) {
                _resetAnimation(); // démarre
              } else {
                _animationController.stop(); // arrête
              }
            });
          },
        ),
        Text(
          _isAnimating ? "Animation activée" : "Animation désactivée",
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSections(Map<String, int> data) {
    List<PieChartSectionData> sections = [];
    int index = 0;

    data.forEach((key, value) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 16 : 14;
      final double radius = isTouched ? 115 : 100;
      final color = _colorList[index % _colorList.length];
      final percentage = value / _users.length * 100;

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
            if (newValue != null && newValue != _selectedChartType) {
              setState(() {
                _selectedChartType = newValue;
                touchedIndex =
                    -1; // Réinitialiser l'index touché lors du changement de vue
                _resetAnimation();
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
                    color: _colorList[1],
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
        return 'Répartition par Sexe';
      case 'age':
        return 'Répartition par Âge';
      case 'region':
        return 'Répartition par Région';
      default:
        return 'Répartition des Clients';
    }
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
        for (var user in users) {
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
    if (age < 45) return '35-44';
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
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF333333)),
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
