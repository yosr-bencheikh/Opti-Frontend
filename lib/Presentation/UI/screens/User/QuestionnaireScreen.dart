import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProGlassesQuestionnaireScreen extends StatefulWidget {
  @override
  _ProGlassesQuestionnaireScreenState createState() =>
      _ProGlassesQuestionnaireScreenState();
}

class _ProGlassesQuestionnaireScreenState
    extends State<ProGlassesQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;

  // Store detailed answers (each answer can now be a Map or List of Maps)
  Map<int, dynamic> _answers = {};

  // Track selected options for multi-select questions
  List<dynamic> _currentSelections = [];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "Quel type de lunettes souhaitez-vous ?",
      'type': 'single', // This remains single selection
      'options': [
        {
          'label': 'Lunettes de Soleil',
          'image': 'assets/images/sun.jpeg',
        },
        {
          'label': 'Lunettes de Vue',
          'image': 'assets/images/vu.jpeg',
        }
      ],
      'icon': Icons.wb_sunny,
    },
    {
      'question': "Quel style vous correspond le mieux ?",
      'type': 'single', // This remains single selection
      'options': [
        {'label': 'Féminin', 'image': 'assets/images/femme.avif'},
        {'label': 'Masculin', 'image': 'assets/images/homme.avif'}
      ],
      'icon': Icons.female,
    },
    {
      'question': "Quelle forme de monture vous convient ?",
      'type': 'multiple', // Changed to multiple selection
      'options': [
        {
          'label': 'Cat Eye',
          'image': 'assets/images/catEye.jpeg',
        },
        {
          'label': 'Aviateur',
          'image': 'assets/images/avaiateur.jpg',
        },
        {
          'label': 'Rond',
          'image': 'assets/images/rond.png',
        },
        {
          'label': 'Carré',
          'image': 'assets/images/carre.jpg',
        },
        {
          'label': 'Rectangle',
          'image': 'assets/images/rectangle.png',
        }
      ],
      'icon': Icons.style,
    },
    {
      'question': "Quelles couleurs aimez-vous ?",
      'type': 'multiple', // Changed to multiple selection
      'options': [
        {
          'label': 'Neutres',
          'image': 'assets/images/neutre.png',
        },
        {
          'label': 'Noir',
          'image': 'assets/images/black.png',
        },
        {
          'label': 'Argent',
          'image': 'assets/images/silver.jpg',
        },
        {
          'label': 'Colorées',
          'image': 'assets/images/color.png',
        }
      ],
      'icon': Icons.color_lens,
    },
    {
      'question': "Quel matériau privilégiez-vous ?",
      'type': 'multiple', // Changed to multiple selection
      'options': [
        {
          'label': 'Plastique',
          'image': 'assets/images/acetate.webp',
        },
        {
          'label': 'Métal',
          'image': 'assets/images/metal.jpg',
        },
        {
          'label': 'Mixte',
          'image': 'assets/images/mixte.jpg',
        }
      ],
      'icon': Icons.build,
    },
    {
      'question': "Quel est votre budget ?",
      'type': 'single', // This remains single selection
      'options': [
        {
          'label': 'Économique (100-250€)',
          'image': 'assets/images/low.jpg',
        },
        {
          'label': 'Moyen (250-500€)',
          'image': 'assets/images/pocket.jpg',
        },
        {
          'label': 'Haut de gamme (800€+)',
          'image': 'assets/images/high.jpg',
        },
      ],
      'icon': Icons.attach_money,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentSelections = [];
  }

  void _nextQuestion() {
    // For multiple selection questions, save the current selections
    if (_questions[_currentQuestionIndex]['type'] == 'multiple' &&
        _currentSelections.isNotEmpty) {
      _answers[_currentQuestionIndex] = [..._currentSelections];
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        // Clear selections for the next question
        _currentSelections = [];

        // Pre-fill if user is going back and forth between questions
        if (_answers.containsKey(_currentQuestionIndex)) {
          if (_questions[_currentQuestionIndex]['type'] == 'multiple') {
            _currentSelections = [..._answers[_currentQuestionIndex]];
          }
        }
      });
      _pageController.nextPage(
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _showDetailedSummary();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      // Save current selections before moving back
      if (_questions[_currentQuestionIndex]['type'] == 'multiple' &&
          _currentSelections.isNotEmpty) {
        _answers[_currentQuestionIndex] = [..._currentSelections];
      }

      setState(() {
        _currentQuestionIndex--;
        // Load the previous selections if available
        _currentSelections = [];
        if (_answers.containsKey(_currentQuestionIndex)) {
          if (_questions[_currentQuestionIndex]['type'] == 'multiple') {
            _currentSelections = [..._answers[_currentQuestionIndex]];
          }
        }
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleSelection(dynamic option) {
    setState(() {
      // For single selection questions
      if (_questions[_currentQuestionIndex]['type'] == 'single') {
        _answers[_currentQuestionIndex] = option;
        _nextQuestion();
        return;
      }

      // For multiple selection questions
      bool alreadySelected = _currentSelections
          .any((selected) => selected['label'] == option['label']);

      if (alreadySelected) {
        _currentSelections
            .removeWhere((selected) => selected['label'] == option['label']);
      } else {
        _currentSelections.add(option);
      }
    });
  }

  bool _isOptionSelected(dynamic option) {
    if (_questions[_currentQuestionIndex]['type'] == 'single') {
      if (_answers.containsKey(_currentQuestionIndex)) {
        return _answers[_currentQuestionIndex]['label'] == option['label'];
      }
      return false;
    } else {
      return _currentSelections
          .any((selected) => selected['label'] == option['label']);
    }
  }

  void _showDetailedSummary() {
    // Make sure we save the last question's answers if it's multi-select
    if (_questions[_currentQuestionIndex]['type'] == 'multiple' &&
        _currentSelections.isNotEmpty) {
      _answers[_currentQuestionIndex] = [..._currentSelections];
    }

    // Create the summary screen
    Get.to(
      () => SummaryScreen(
        answers: _answers,
        questions: _questions,
        onConfirm: () {
          // Navigate to recommendations screen and pass answers
          Get.offNamed('/recommendations', arguments: _answers);
        },
      ),
      transition: Transition.rightToLeftWithFade,
      duration: Duration(milliseconds: 500),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    bool isMultipleSelection = question['type'] == 'multiple';
    final screenWidth = MediaQuery.of(context).size.width;

    return Animate(
      effects: [
        FadeEffect(duration: 500.ms),
        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero)
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question['question'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.deepPurple[900],
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16),
          if (isMultipleSelection)
            Text(
              "Sélectionnez une ou plusieurs options",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                var option = question['options'][index];
                bool isSelected = _isOptionSelected(option);

                return GestureDetector(
                  onTap: () => _toggleSelection(option),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey[200]!,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(18)),
                                    ),
                                    child: Image.asset(
                                      option['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Text(
                                    option['label'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: _nextQuestion,
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.skip_next, size: 20),
                SizedBox(width: 8),
                Text(
                  "Passer cette question",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (isMultipleSelection)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _currentSelections.isNotEmpty ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                icon: Icon(Icons.arrow_forward_rounded, size: 22),
                label: Text(
                  "Continuer",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0)
            TextButton(
              onPressed: _previousQuestion,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Précédent",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.deepPurple[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionWidget(_questions[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecommendationsScreen extends StatelessWidget {
  final ProductController _productController = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    final Map<int, dynamic> answers =
        Get.arguments is Map ? (Get.arguments as Map).cast<int, dynamic>() : {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Vos Recommandations',
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.deepPurple[800]),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_productController.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.deepPurple),
                SizedBox(height: 16),
                Text(
                  'Recherche des lunettes idéales pour vous...',
                  style: TextStyle(
                    color: Colors.deepPurple[800],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (_productController.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                SizedBox(height: 16),
                Text(
                  'Erreur: ${_productController.error}',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _productController.loadProducts(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final recommendedProducts =
            _filterProducts(_productController.products, answers);

        if (recommendedProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                SizedBox(height: 24),
                Text(
                  'Aucun produit correspondant à vos critères.',
                  style: TextStyle(fontSize: 18, color: Colors.deepPurple[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Essayez de modifier vos préférences pour obtenir plus de résultats.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Modifier les préférences'),
                ),
              ],
            ),
          );
        }

        return ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildHeaderSection(recommendedProducts.length),
            _buildProductListSection(recommendedProducts),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderSection(int productCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$productCount ${productCount > 1 ? 'Modèles Trouvés' : 'Modèle Trouvé'}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[800],
            ),
          ).animate().fadeIn(duration: 600.ms),
          SizedBox(height: 8),
          Text(
            "Voici les lunettes qui correspondent parfaitement à vos préférences",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildProductListSection(List<Product> products) {
    return Column(
      children: products.map((product) {
        return ProductCard(
          product: product,
          onTap: () => Get.toNamed('/product-details', arguments: product.id),
        );
      }).toList(),
    );
  }

  Color _getColorFromString(String colorName) {
    // Map common color names to actual colors
    final colorMap = {
      'noir': Colors.black,
      'black': Colors.black,
      'blanc': Colors.white,
      'white': Colors.white,
      'rouge': Colors.red,
      'red': Colors.red,
      'bleu': Colors.blue,
      'blue': Colors.blue,
      'vert': Colors.green,
      'green': Colors.green,
      'jaune': Colors.yellow,
      'yellow': Colors.yellow,
      'marron': Colors.brown,
      'brown': Colors.brown,
      'gris': Colors.grey,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'argent': Colors.grey[300]!,
      'silver': Colors.grey[300]!,
      'or': Colors.amber,
      'gold': Colors.amber,
      'rose': Colors.pink,
      'pink': Colors.pink,
      'violet': Colors.purple,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'écaille': Colors.brown[400]!,
      'ecaille': Colors.brown[400]!,
      'havana': Colors.brown[400]!,
      'tortoise': Colors.brown[400]!,
    };

    // Look for matching color in the color name
    for (var entry in colorMap.entries) {
      if (colorName.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    // Default color if no match is found
    return Colors.grey[500]!;
  }

  List<Product> _filterProducts(
      List<Product> allProducts, Map<int, dynamic> answers) {
    List<Product> filteredProducts = [...allProducts];

    // Si aucune réponse n'a été donnée (toutes les questions ont "Pas de préférence")
    if (answers.isEmpty) {
      return filteredProducts;
    }

    // Filtrer par type (question 0)
    if (answers.containsKey(0)) {
      String selectedType = answers[0]['label'];
      filteredProducts = filteredProducts.where((product) {
        if (selectedType == 'Lunettes de Soleil') {
          return product.category.toLowerCase().contains('soleil');
        } else if (selectedType == 'Lunettes de Vue') {
          return product.category.toLowerCase().contains('vue');
        }
        return true;
      }).toList();
    }

    // Filtrer par style (question 1)
    if (answers.containsKey(1)) {
      String selectedStyle = answers[1]['label'];
      filteredProducts = filteredProducts.where((product) {
        if (selectedStyle == 'Féminin') {
          return product.sexe.toLowerCase() == 'feminin' ||
              product.sexe.toLowerCase() == 'unisexe';
        } else if (selectedStyle == 'Masculin') {
          return product.sexe.toLowerCase() == 'masculin' ||
              product.sexe.toLowerCase() == 'unisexe';
        }
        return true;
      }).toList();
    }

    // Filtrer par forme (question 2)
    if (answers.containsKey(2)) {
      List<String> selectedShapes = (answers[2] as List)
          .map((e) => e['label'].toString().toLowerCase())
          .toList();

      filteredProducts = filteredProducts.where((product) {
        if (product.style == null || product.style!.isEmpty) return false;

        String productStyle = product.style!.toLowerCase();

        // Vérifier les correspondances exactes ou partielles
        for (var shape in selectedShapes) {
          if (shape.contains('cat') && productStyle.contains('cat'))
            return true;
          if (shape.contains('avi') && productStyle.contains('avi'))
            return true;
          if (shape.contains('rond') && productStyle.contains('rond'))
            return true;
          if (shape.contains('carré') && productStyle.contains('carré'))
            return true;
          if (shape.contains('rect') && productStyle.contains('rect'))
            return true;
          if (productStyle.contains(shape)) return true;
        }
        return false;
      }).toList();
    }

    // Filtrer par couleur (question 3)
    if (answers.containsKey(3)) {
      List<String> selectedColors = (answers[3] as List)
          .map((e) => e['label'].toString().toLowerCase())
          .toList();

      filteredProducts = filteredProducts.where((product) {
        if (product.couleur.isEmpty) return false;

        // Pour chaque couleur choisie par l'utilisateur
        for (var selectedColor in selectedColors) {
          // Pour chaque couleur du produit
          for (var productColor in product.couleur) {
            String colorLower = productColor.toLowerCase();

            // Si l'utilisateur a choisi "noir"
            if (selectedColor == 'noir') {
              if (_isBlackColor(colorLower)) return true;
            }
            // Si l'utilisateur a choisi "neutres" (et exclure les noirs)
            else if (selectedColor == 'neutres') {
              if (!_isBlackColor(colorLower) && _isNeutralColor(colorLower))
                return true;
            }
            // Si l'utilisateur a choisi "argent"
            else if (selectedColor == 'argent') {
              if (_isSilverColor(colorLower)) return true;
            }
            // Si l'utilisateur a choisi "colorées"
            else if (selectedColor == 'colorées') {
              if (_isColorfulColor(colorLower)) return true;
            }
            // Pour les autres couleurs spécifiques
            else if (colorLower.contains(selectedColor)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    // Filtrer par matériau (question 4)
    if (answers.containsKey(4)) {
      List<String> selectedMaterials = (answers[4] as List)
          .map((e) => e['label'].toString().toLowerCase())
          .toList();

      filteredProducts = filteredProducts.where((product) {
        if (product.materiel == null || product.materiel!.isEmpty) return false;

        String material = product.materiel!.toLowerCase();

        for (var selectedMaterial in selectedMaterials) {
          if (selectedMaterial == 'plastique' &&
              (material.contains('plast') || material.contains('acétate')))
            return true;
          if (selectedMaterial == 'métal' && material.contains('métal'))
            return true;
          if (selectedMaterial == 'mixte' && material.contains('mixte'))
            return true;
          if (material.contains(selectedMaterial)) return true;
        }
        return false;
      }).toList();
    }

    // Filtrer par budget (question 5)
    if (answers.containsKey(5)) {
      String selectedBudget = answers[5]['label'];

      filteredProducts = filteredProducts.where((product) {
        if (selectedBudget.contains('Économique')) {
          return product.prix <= 250;
        } else if (selectedBudget.contains('Moyen')) {
          return product.prix > 250 && product.prix <= 500;
        } else if (selectedBudget.contains('Haut')) {
          return product.prix > 800;
        }
        return true;
      }).toList();
    }

    return filteredProducts;
  }

  // Helper methods for color detection
  bool _isBlackColor(String color) {
    // Vérification des noms de couleur noir
    if (color.contains('noir') || color.contains('black')) {
      return true;
    }

    // Vérification des codes hex noir
    if (color.startsWith('#')) {
      try {
        final rgb = ColorUtils.hexToRgb(color);
        // Vérifie si tous les composants sont très foncés (< 60)
        return rgb['r']! < 60 && rgb['g']! < 60 && rgb['b']! < 60;
      } catch (_) {
        return false;
      }
    }

    // Vérification des codes hex sans #
    if (color == '000000' || color == '000') {
      return true;
    }

    return false;
  }

  bool _isNeutralColor(String color) {
    // Exclure explicitement les couleurs noires
    if (_isBlackColor(color)) {
      return false;
    }

    // Convertir en minuscules et supprimer les #
    String normalizedColor = color.toLowerCase().replaceAll('#', '');

    // Si c'est un code hex, utiliser ColorUtils
    if (color.toLowerCase().startsWith('#') ||
        (normalizedColor.length == 6 &&
            RegExp(r'^[0-9a-f]{6}$').hasMatch(normalizedColor))) {
      return ColorUtils.isNeutral(color);
    }

    // Noms de couleurs neutres (exclure noir)
    return normalizedColor.contains('beige') ||
        normalizedColor.contains('taupe') ||
        normalizedColor.contains('marron') ||
        normalizedColor.contains('brown') ||
        normalizedColor.contains('tan') ||
        normalizedColor.contains('écaille') ||
        normalizedColor.contains('ecaille') ||
        normalizedColor.contains('havana') ||
        normalizedColor.contains('tortoise');
  }

  bool _isSilverColor(String color) {
    // Convertir en minuscules et supprimer les #
    String normalizedColor = color.toLowerCase().replaceAll('#', '');

    // Si c'est un code hex, utiliser ColorUtils
    if (color.toLowerCase().startsWith('#') ||
        (normalizedColor.length == 6 &&
            RegExp(r'^[0-9a-f]{6}$').hasMatch(normalizedColor))) {
      return ColorUtils.isSilver(color);
    }

    // Noms de couleurs argentées
    return normalizedColor.contains('argent') ||
        normalizedColor.contains('silver') ||
        normalizedColor.contains('gris') ||
        normalizedColor.contains('gray') ||
        normalizedColor.contains('grey');
  }

  bool _isColorfulColor(String color) {
    // Exclure les couleurs noires
    if (_isBlackColor(color)) {
      return false;
    }

    // Convertir en minuscules et supprimer les #
    String normalizedColor = color.toLowerCase().replaceAll('#', '');

    // Si c'est un code hex, utiliser ColorUtils
    if (color.toLowerCase().startsWith('#') ||
        (normalizedColor.length == 6 &&
            RegExp(r'^[0-9a-f]{6}$').hasMatch(normalizedColor))) {
      return ColorUtils.isColorful(color);
    }

    // Noms de couleurs vives
    return normalizedColor.contains('rouge') ||
        normalizedColor.contains('red') ||
        normalizedColor.contains('bleu') ||
        normalizedColor.contains('blue') ||
        normalizedColor.contains('vert') ||
        normalizedColor.contains('green') ||
        normalizedColor.contains('jaune') ||
        normalizedColor.contains('yellow') ||
        normalizedColor.contains('rose') ||
        normalizedColor.contains('pink') ||
        normalizedColor.contains('violet') ||
        normalizedColor.contains('purple') ||
        normalizedColor.contains('orange') ||
        normalizedColor.contains('turquoise') ||
        normalizedColor.contains('cyan') ||
        normalizedColor.contains('magenta') ||
        normalizedColor.contains('fuchsia') ||
        normalizedColor.contains('coral');
  }

  // Helper function to convert hex string to Color
  Color getColorFromHex(String hexString) {
    // Remove # if present
    final hexCode = hexString.replaceAll('#', '');

    // Ensure we have a 6-digit hex code
    if (hexCode.length == 6) {
      // Parse the hex code to an integer and add the full opacity value (0xFF)
      return Color(int.parse('0xFF$hexCode'));
    } else {
      // Default to black if invalid hex
      return Colors.black;
    }
  }
}

class ColorUtils {
  static Map<String, int> hexToRgb(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((c) => c + c).join('');
    }
    return {
      'r': int.parse(hexColor.substring(0, 2), radix: 16),
      'g': int.parse(hexColor.substring(2, 4), radix: 16),
      'b': int.parse(hexColor.substring(4, 6), radix: 16),
    };
  }

  static bool isColorful(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final maxVal =
          [rgb['r']!, rgb['g']!, rgb['b']!].reduce((a, b) => a > b ? a : b);
      final minVal =
          [rgb['r']!, rgb['g']!, rgb['b']!].reduce((a, b) => a < b ? a : b);

      // Calculate saturation (0-255)
      final saturation = maxVal - minVal;

      // Adjustable thresholds
      return saturation > 50 &&
          maxVal > 50 &&
          (maxVal - minVal) / maxVal > 0.25;
    } catch (_) {
      return false;
    }
  }

  static bool isNeutral(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final avg = (rgb['r']! + rgb['g']! + rgb['b']!) / 3;
      final diff = (rgb['r']! - avg).abs() +
          (rgb['g']! - avg).abs() +
          (rgb['b']! - avg).abs();
      return diff < 50; // Lower value means more neutral
    } catch (_) {
      return false;
    }
  }

  static bool isSilver(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final avg = (rgb['r']! + rgb['g']! + rgb['b']!) / 3;
      return avg > 150 && // Light color
          (rgb['r']! - avg).abs() < 30 &&
          (rgb['g']! - avg).abs() < 30 &&
          (rgb['b']! - avg).abs() < 30;
    } catch (_) {
      return false;
    }
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec placeholder si vide
            AspectRatio(
              aspectRatio: 1,
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.marque,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.prix} DT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      if (product.model3D.isNotEmpty)
                        Chip(
                          label: Text('3D'),
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (product.style.isNotEmpty)
                        Chip(
                          label: Text(product.style),
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        ),
                      if (product.materiel.isNotEmpty)
                        Chip(
                          label: Text(product.materiel),
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.photo,
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

// Create a new SummaryScreen widget
class SummaryScreen extends StatelessWidget {
  final Map<int, dynamic> answers;
  final List<Map<String, dynamic>> questions;
  final Function onConfirm;

  const SummaryScreen({
    Key? key,
    required this.answers,
    required this.questions,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Vos Préférences",
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.deepPurple[800]),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Merci d'avoir complété notre questionnaire !",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple[700],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  SizedBox(height: 10),
                  Text(
                    "Voici le résumé de vos préférences :",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  SizedBox(height: 30),
                  ...answers.entries.map((entry) {
                    var question = questions[entry.key];
                    int index = entry.key;
                    return _buildSummaryCard(question, entry.value, index);
                  }).toList(),
                ],
              ),
            ),
          ),
          _buildFooterButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      Map<String, dynamic> question, dynamic value, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.deepPurple.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(
                    question['icon'] ?? Icons.check_circle_outline,
                    color: Colors.deepPurple[600],
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question['question'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle both single and multiple selections
                  if (value is Map)
                    _buildAnswerItem(value['label'])
                  else if (value is List)
                    ...List<dynamic>.from(value)
                        .asMap()
                        .entries
                        .map((item) =>
                            _buildAnswerItem(item.value['label'], item.key))
                        .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (500 + (index * 200)).ms, duration: 600.ms)
        .slideY(
          begin: 0.3,
          end: 0,
          delay: (500 + (index * 200)).ms,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildAnswerItem(String label, [int? index]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple[400],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
        delay: index != null ? (100 * index).ms : 0.ms, duration: 400.ms);
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 0,
                side: BorderSide(color: Colors.deepPurple),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Modifier"),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onConfirm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Voir mes recommandations"),
            ),
          ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
        ],
      ),
    );
  }
}
