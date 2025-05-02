import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/User/enhanced_product_card.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/Presentation/widgets/productCard.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

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
        {'label': 'Féminin', 'image': 'assets/images/femme.jpg'},
        {'label': 'Masculin', 'image': 'assets/images/homme.jpg'}
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
          'label': 'Économique (100-250 TND)',
          'image': 'assets/images/low.jpg',
        },
        {
          'label': 'Moyen (250-500 TND)',
          'image': 'assets/images/pocket.jpg',
        },
        {
          'label': 'Haut de gamme (800TND+)',
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
  final ProductController _productController = Get.find();

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
          return _buildLoadingIndicator();
        }

        if (_productController.error != null) {
          return _buildErrorState();
        }

        final recommendedProducts =
            _filterProducts(_productController.products, answers);

        return recommendedProducts.isEmpty
            ? _buildEmptyState()
            : _buildProductList(recommendedProducts);
      }),
    );
  }

  Widget _buildLoadingIndicator() {
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

  Widget _buildErrorState() {
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

  Widget _buildEmptyState() {
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

  Widget _buildProductList(List<Product> products) {
    return ListView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildHeaderSection(products.length),
        _buildProductGrid(products),
      ],
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

  Widget _buildProductGrid(List<Product> products) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) =>
            EnhancedProductCard(product: products[index]),
      ),
    );
  }

  List<Product> _filterProducts(
      List<Product> allProducts, Map<int, dynamic> answers) {
    print('[DEBUG] Starting filter process...');
    print('[DEBUG] Initial product count: ${allProducts.length}');
    print('[DEBUG] Filter criteria: $answers');

    List<Product> filteredProducts = [...allProducts];

    // If no answers were given (all questions have "No preference")
    if (answers.isEmpty) {
      print('[DEBUG] No filter criteria provided, returning all products');
      return filteredProducts;
    }

    // Filter by type (question 0) - This is the most important filter
    if (answers.containsKey(0)) {
      String selectedType = answers[0]['label'];
      print('[DEBUG] Filtering by type: $selectedType');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        // Normalize category names for comparison
        String normalizedCategory = product.category.toLowerCase().trim();
        bool matches = false;

        if (selectedType == 'Lunettes de Soleil') {
          matches = normalizedCategory.contains('solaire') ||
              normalizedCategory.contains('soleil');
        } else if (selectedType == 'Lunettes de Vue') {
          matches = normalizedCategory.contains('vue') ||
              normalizedCategory.contains('vision') ||
              normalizedCategory.contains('corrective');
        } else {
          matches = true;
        }

        print(
            '[DEBUG] Product ${product.name} category: $normalizedCategory, matches type $selectedType: $matches');
        return matches;
      }).toList();

      print(
          '[DEBUG] Type filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    // Filter by style (question 1)
    if (answers.containsKey(1)) {
      String selectedStyle = answers[1]['label'];
      print('[DEBUG] Filtering by style: $selectedStyle');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        if (product.sexe.isEmpty) {
          print(
              '[DEBUG] Product ${product.name} has no gender info, excluding');
          return false;
        }

        String normalizedSexe = product.sexe.toLowerCase().trim();
        bool matches = false;

        if (selectedStyle == 'Féminin') {
          matches = normalizedSexe == 'feminin' ||
              normalizedSexe == 'femme' ||
              normalizedSexe == 'unisexe';
        } else if (selectedStyle == 'Masculin') {
          matches = normalizedSexe == 'masculin' ||
              normalizedSexe == 'homme' ||
              normalizedSexe == 'unisexe';
        } else {
          matches = true;
        }

        print(
            '[DEBUG] Product ${product.name} gender: $normalizedSexe, matches style $selectedStyle: $matches');
        return matches;
      }).toList();

      print(
          '[DEBUG] Style filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    // Filter by shape (question 2)
    if (answers.containsKey(2)) {
      List<String> selectedShapes = (answers[2] as List)
          .map((e) => e['label'].toString().toLowerCase().trim())
          .toList();
      print('[DEBUG] Filtering by shapes: $selectedShapes');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        if (product.style.isEmpty) {
          print('[DEBUG] Product ${product.name} has no style info, excluding');
          return false;
        }

        String productStyle = product.style.toLowerCase().trim();
        bool matches = false;

        // Check for exact or partial matches
        for (var shape in selectedShapes) {
          if (shape.contains('cat') && productStyle.contains('cat eye')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
          if (shape.contains('avi') && productStyle.contains('avi')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
          if (shape.contains('rond') && productStyle.contains('rond')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
          if (shape.contains('carré') && productStyle.contains('carré')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
          if (shape.contains('rect') && productStyle.contains('rect')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
          if (productStyle.contains(shape)) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} style: $productStyle, matches shape $shape');
            break;
          }
        }

        if (!matches) {
          print(
              '[DEBUG] Product ${product.name} style: $productStyle, does NOT match any selected shapes');
        }
        return matches;
      }).toList();

      print(
          '[DEBUG] Shape filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    // Filter by color (question 3)
    if (answers.containsKey(3)) {
      List<String> selectedColors = (answers[3] as List)
          .map((e) => e['label'].toString().toLowerCase().trim())
          .toList();
      print('[DEBUG] Filtering by colors: $selectedColors');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        if (product.couleur.isEmpty) {
          print('[DEBUG] Product ${product.name} has no color info, excluding');
          return false;
        }

        // For each color chosen by the user
        bool matches = false;

        for (var selectedColor in selectedColors) {
          // For each color of the product
          for (var productColor in product.couleur) {
            String colorLower = productColor.toLowerCase().trim();

            // Check if the color is a hex code and match it to named colors
            if (_isHexColor(colorLower)) {
              // If user chose "noir" and the hex code is for black
              if (selectedColor == 'noir' && _isHexBlack(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} hex color: $colorLower matches "noir"');
                break;
              }
              // If user chose "neutres" and the hex code is for a neutral color
              else if (selectedColor == 'neutres' &&
                  !_isHexBlack(colorLower) &&
                  _isHexNeutral(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} hex color: $colorLower matches "neutres"');
                break;
              }
              // If user chose "argent" and the hex code is for silver
              else if (selectedColor == 'argent' && _isHexSilver(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} hex color: $colorLower matches "argent"');
                break;
              }
              // If user chose "colorées" and the hex code is for a colorful color
              else if (selectedColor == 'colorées' &&
                  _isHexColorful(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} hex color: $colorLower matches "colorées"');
                break;
              }
            }
            // Also keep the original text-based matching
            else {
              // If user chose "noir"
              if (selectedColor == 'noir' && _isBlackColor(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} text color: $colorLower matches "noir"');
                break;
              }
              // If user chose "neutres"
              else if (selectedColor == 'neutres' &&
                  !_isBlackColor(colorLower) &&
                  _isNeutralColor(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} text color: $colorLower matches "neutres"');
                break;
              }
              // If user chose "argent"
              else if (selectedColor == 'argent' &&
                  _isSilverColor(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} text color: $colorLower matches "argent"');
                break;
              }
              // If user chose "colorées"
              else if (selectedColor == 'colorées' &&
                  _isColorfulColor(colorLower)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} text color: $colorLower matches "colorées"');
                break;
              }
              // For other specific colors
              else if (colorLower.contains(selectedColor)) {
                matches = true;
                print(
                    '[DEBUG] Product ${product.name} color: $colorLower matches "$selectedColor"');
                break;
              }
            }
          }
          if (matches) break;
        }

        if (!matches) {
          print(
              '[DEBUG] Product ${product.name} colors: ${product.couleur}, does NOT match any selected colors');
        }
        return matches;
      }).toList();

      print(
          '[DEBUG] Color filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    // Filter by material (question 4)
    if (answers.containsKey(4)) {
      List<String> selectedMaterials = (answers[4] as List)
          .map((e) => e['label'].toString().toLowerCase().trim())
          .toList();
      print('[DEBUG] Filtering by materials: $selectedMaterials');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        if (product.materiel == null || product.materiel!.isEmpty) {
          print(
              '[DEBUG] Product ${product.name} has no material info, excluding');
          return false;
        }

        String material = product.materiel!.toLowerCase().trim();
        bool matches = false;

        for (var selectedMaterial in selectedMaterials) {
          if (selectedMaterial == 'plastique' &&
              (material.contains('plast') || material.contains('acétate'))) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} material: $material, matches "plastique"');
            break;
          }
          if (selectedMaterial == 'métal' && material.contains('métal')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} material: $material, matches "métal"');
            break;
          }
          if (selectedMaterial == 'mixte' && material.contains('mixte')) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} material: $material, matches "mixte"');
            break;
          }
          if (material.contains(selectedMaterial)) {
            matches = true;
            print(
                '[DEBUG] Product ${product.name} material: $material, matches "$selectedMaterial"');
            break;
          }
        }

        if (!matches) {
          print(
              '[DEBUG] Product ${product.name} material: $material, does NOT match any selected materials');
        }
        return matches;
      }).toList();

      print(
          '[DEBUG] Material filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    // Filter by budget (question 5)
    if (answers.containsKey(5)) {
      String selectedBudget = answers[5]['label'];
      print('[DEBUG] Filtering by budget: $selectedBudget');

      int beforeCount = filteredProducts.length;
      filteredProducts = filteredProducts.where((product) {
        bool matches = false;

        if (selectedBudget.contains('Économique')) {
          matches = product.prix <= 250;
        } else if (selectedBudget.contains('Moyen')) {
          matches = product.prix > 250 && product.prix <= 500;
        } else if (selectedBudget.contains('Haut')) {
          matches = product.prix > 500;
        } else {
          matches = true;
        }

        print(
            '[DEBUG] Product ${product.name} price: ${product.prix}, matches budget $selectedBudget: $matches');
        return matches;
      }).toList();

      print(
          '[DEBUG] Budget filter: ${beforeCount} → ${filteredProducts.length} products (removed ${beforeCount - filteredProducts.length})');
    }

    print('[DEBUG] Final filtered product count: ${filteredProducts.length}');
    if (filteredProducts.isEmpty) {
      print('[WARNING] No products matched the filtering criteria!');
    } else {
      print('[DEBUG] Top 5 matching products:');
      for (int i = 0; i < min(5, filteredProducts.length); i++) {
        print(
            '  - ${filteredProducts[i].name} (${filteredProducts[i].category})');
      }
    }

    return filteredProducts;
  }

  bool _isHexColor(String color) {
    // Check if it's a hex color (with or without #)
    return RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$').hasMatch(color);
  }

// Helper function to determine if a hex color is black
  bool _isHexBlack(String hexColor) {
    // Remove # if present
    hexColor = hexColor.replaceAll('#', '');

    // Check if it's black (000000) or very dark
    if (hexColor == '000000') return true;

    // Handle 3-digit hex codes
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((e) => e + e).join();
    }

    // If it's a 6-digit hex, check if it's a very dark color
    if (hexColor.length == 6) {
      try {
        int r = int.parse(hexColor.substring(0, 2), radix: 16);
        int g = int.parse(hexColor.substring(2, 4), radix: 16);
        int b = int.parse(hexColor.substring(4, 6), radix: 16);

        // Very dark colors (close to black)
        return r < 30 && g < 30 && b < 30;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  bool _isHexNeutral(String hexColor) {
    // Remove # if present
    hexColor = hexColor.replaceAll('#', '');

    // Handle 3-digit hex codes
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((e) => e + e).join();
    }

    if (hexColor.length == 6) {
      try {
        int r = int.parse(hexColor.substring(0, 2), radix: 16);
        int g = int.parse(hexColor.substring(2, 4), radix: 16);
        int b = int.parse(hexColor.substring(4, 6), radix: 16);

        // Calculate saturation (0-1)
        int max = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
        int min = [r, g, b].reduce((curr, next) => curr < next ? curr : next);
        double saturation = max == 0 ? 0 : (max - min) / max;

        // White or very light colors
        if (r > 220 && g > 220 && b > 220) return true;

        // Pure grays (equal RGB values)
        if ((r - g).abs() < 10 && (r - b).abs() < 10 && (g - b).abs() < 10) {
          return true;
        }

        // Beige and brown colors (combinations of red and green with low saturation)
        if (r > g && g > b && saturation < 0.5) return true;

        // Earthy tones (low saturation)
        if (saturation < 0.25) return true;

        // Desaturated colors are considered neutral
        return saturation < 0.3;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

// Helper function to determine if a hex color is silver
  bool _isHexSilver(String hexColor) {
    // Remove # if present
    hexColor = hexColor.replaceAll('#', '');

    // Handle 3-digit hex codes
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((e) => e + e).join();
    }

    if (hexColor.length == 6) {
      try {
        int r = int.parse(hexColor.substring(0, 2), radix: 16);
        int g = int.parse(hexColor.substring(2, 4), radix: 16);
        int b = int.parse(hexColor.substring(4, 6), radix: 16);

        // Silver/metallic colors (light grays where r, g, b are close)
        return r > 160 &&
            g > 160 &&
            b > 160 &&
            (r - g).abs() < 20 &&
            (r - b).abs() < 20 &&
            (g - b).abs() < 20;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  bool _isHexColorful(String hexColor) {
    // Remove # if present
    hexColor = hexColor.replaceAll('#', '');

    // Handle 3-digit hex codes
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((e) => e + e).join();
    }

    if (hexColor.length == 6) {
      try {
        int r = int.parse(hexColor.substring(0, 2), radix: 16);
        int g = int.parse(hexColor.substring(2, 4), radix: 16);
        int b = int.parse(hexColor.substring(4, 6), radix: 16);

        // Calculate saturation
        int max = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
        int min = [r, g, b].reduce((curr, next) => curr < next ? curr : next);
        double saturation = max == 0 ? 0 : (max - min) / max.toDouble();

        // Colors with significant saturation
        if (saturation > 0.4) return true;

        // Red/pink dominant
        if (r > g + 60 && r > b + 60) return true;

        // Green dominant
        if (g > r + 60 && g > b + 60) return true;

        // Blue/purple dominant
        if (b > r + 60 && b > g + 60) return true;

        // Yellow (high red and green)
        if (r > 180 && g > 180 && b < r - 100 && b < g - 100) return true;

        // Specific vibrant color detection
        if (max > 180 && (max - min) > 100) return true;

        return false;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

// Helper function to determine if a string represents a "black" color
  bool _isBlackColor(String color) {
    return color.contains('noir') || color.contains('black');
  }

// Helper function to determine if a string represents a "neutral" color
  bool _isNeutralColor(String color) {
    return color.contains('beige') ||
        color.contains('écaille') ||
        color.contains('tortoise') ||
        color.contains('marron') ||
        color.contains('brun') ||
        color.contains('havane') ||
        color.contains('transparent') ||
        color.contains('gris') ||
        color.contains('grey') ||
        color.contains('taupe') ||
        color.contains('blanc') ||
        color.contains('white');
  }

// Helper function to determine if a string represents a "silver" color
  bool _isSilverColor(String color) {
    return color.contains('argent') ||
        color.contains('silver') ||
        color.contains('chrome') ||
        color.contains('métal');
  }

// Helper function to determine if a string represents a "colorful" color
  bool _isColorfulColor(String color) {
    return color.contains('rouge') ||
        color.contains('red') ||
        color.contains('bleu') ||
        color.contains('blue') ||
        color.contains('vert') ||
        color.contains('green') ||
        color.contains('jaune') ||
        color.contains('yellow') ||
        color.contains('orange') ||
        color.contains('violet') ||
        color.contains('purple') ||
        color.contains('rose') ||
        color.contains('pink') ||
        color.contains('gold') ||
        color.contains('or') ||
        color.contains('doré');
  }

// Helper function to get min value (for limiting top product list)
  int min(int a, int b) {
    return a < b ? a : b;
  }
  // Helper function to convert hex string to Color
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
              onPressed: () {
                Get.toNamed('/recommandationScreen', arguments: answers);
              },
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
