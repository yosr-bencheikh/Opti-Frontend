import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
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
  final WishlistController wishlistController = Get.find();
  final AuthController authController = Get.find();

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

  Widget _buildProductCard(BuildContext context, Product product) {
    // Normaliser l'URL du modèle 3D
    String normalizedModelUrl =
        product.model3D.isNotEmpty ? _normalizeModelUrl(product.model3D) : '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => ProductDetailsScreen(product: product));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image ou viewer 3D
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: product.model3D.isNotEmpty
                        ? FutureBuilder<bool>(
                            future: _checkModelAvailability(normalizedModelUrl),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasData && snapshot.data == true) {
                                // Utiliser le widget Rotating3DModel avec autoRotate contrôlé par le passage de la souris
                                return Flutter3DViewer(src: product.model3D);
                              } else {
                                // Fallback à l'image si le modèle n'est pas disponible
                                return product.image.isNotEmpty
                                    ? Image.network(product.image,
                                        fit: BoxFit.cover)
                                    : Center(
                                        child: Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey));
                              }
                            },
                          )
                        : product.image.isNotEmpty
                            ? Image.network(product.image, fit: BoxFit.cover)
                            : Center(
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey)),
                  ),
                  // Bouton Wishlist
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: Obx(() {
                        final isInWishlist =
                            wishlistController.isProductInWishlist(product.id!);
                        return Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.red : Colors.grey,
                        );
                      }),
                      onPressed: () => _toggleWishlist(product),
                    ),
                  ),
                ],
              ),
            ),
            // Info produit
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.marque,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${product.prix.toStringAsFixed(2)} TND',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleWishlist(Product product) async {
    final userEmail = authController.currentUser?.email;
    if (userEmail == null) {
      Get.snackbar('Erreur', 'Veuillez vous connecter d\'abord');
      return;
    }

    try {
      final isInWishlist = wishlistController.isProductInWishlist(product.id!);

      if (isInWishlist) {
        await wishlistController.removeFromWishlist(product.id!);
      } else {
        final wishlistItem = WishlistItem(
          userId: userEmail,
          productId: product.id!,
        );
        await wishlistController.addToWishlist(wishlistItem);
      }
    } catch (e) {
      Get.snackbar(
          'Erreur', 'Impossible de mettre à jour la liste de souhaits');
    }
  }

  Future<bool> _checkModelAvailability(String url) async {
    if (url.isEmpty) return false;

    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur de vérification du modèle 3D: $e');
      return false;
    }
  }

  String _normalizeModelUrl(String url) {
    // Implémentez votre logique de normalisation d'URL ici
    return GlassesManagerService.ensureAbsoluteUrl(url);
  }

  Widget _buildProductListSection(List<Product> products) {
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
        itemBuilder: (context, index) {
          return _buildEnhancedProductCard(context, products[index]);
        },
      ),
    );
  }

  Widget _buildEnhancedProductCard(BuildContext context, Product product) {
    String normalizedModelUrl =
        product.model3D.isNotEmpty ? _normalizeModelUrl(product.model3D) : '';

    return Obx(() {
      final isInWishlist = wishlistController.isProductInWishlist(product.id!);
      final Color cardBackgroundColor =
          isInWishlist ? Colors.pink[100]!.withOpacity(0.3) : Color(0xFFF5F3FA);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: Offset(0, 8),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Card Background
              Container(
                color: cardBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section (60% of card height)
                    Expanded(
                      flex: 6,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.grey[50],
                            child: product.model3D.isNotEmpty
                                ? FutureBuilder<bool>(
                                    future: _checkModelAvailability(
                                        normalizedModelUrl),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.deepPurple[300],
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return Flutter3DViewer(
                                            src: product.model3D);
                                      } else {
                                        return product.image.isNotEmpty
                                            ? Hero(
                                                tag: 'product-${product.id}',
                                                child: Image.network(
                                                  product.image,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        color: Colors
                                                            .deepPurple[300],
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                      }
                                    },
                                  )
                                : product.image.isNotEmpty
                                    ? Hero(
                                        tag: 'product-${product.id}',
                                        child: Image.network(
                                          product.image,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                                color: Colors.deepPurple[300],
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[700],
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                '${product.prix.toStringAsFixed(2)} TND',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Info Section (40% of card height)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              cardBackgroundColor,
                              cardBackgroundColor.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.marque,
                                style: TextStyle(
                                  color: Colors.deepPurple[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              product.name,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepPurple[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (product.style.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      product.style,
                                      style: TextStyle(
                                        color: Colors.deepPurple[300],
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (int i = 0;
                                          i < min(product.couleur.length, 3);
                                          i++)
                                        Container(
                                          margin: EdgeInsets.only(right: 4),
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getColorFromString(
                                                product.couleur[i]),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: cardBackgroundColor,
                                                width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 1,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (product.couleur.length > 3)
                                        Container(
                                          margin: EdgeInsets.only(left: 2),
                                          child: Text(
                                            '+${product.couleur.length - 3}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.deepPurple[300],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple[100]!
                                        .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Colors.deepPurple[800],
                                    ),
                                    onPressed: () => Get.to(() =>
                                        ProductDetailsScreen(product: product)),
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
              ),

              // Category tag
              if (product.category.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.category.toLowerCase().contains('soleil')
                          ? Colors.amber[700]
                          : Colors.blue[700],
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      product.category.toLowerCase().contains('soleil')
                          ? 'Soleil'
                          : 'Vue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Tap overlay
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        Get.to(() => ProductDetailsScreen(product: product)),
                    splashColor: Colors.deepPurple.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                  ),
                ),
              ),

              // Wishlist button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBackgroundColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _toggleWishlist(product),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist
                              ? Colors.red[400]
                              : Colors.deepPurple[300],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

// Helper function to convert color strings to Color objects
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

// Keep this helper function which you already had
  Color getColorFromHex(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('0xFF$hexCode'));
    } else {
      return Colors.black;
    }
  }

// Don't forget to add this import at the top of your file

// Don't forget to add this import at the top of your file

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
        if (product.style.isEmpty) return false;

        String productStyle = product.style.toLowerCase();

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
        if (product.materiel == null || product.materiel.isEmpty) return false;

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
                Get.toNamed('/recommandationScreen');
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
