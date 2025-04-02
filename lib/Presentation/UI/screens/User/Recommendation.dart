import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

class RecommendationScreen extends StatefulWidget {
  final String faceShape;

  const RecommendationScreen({Key? key, required this.faceShape})
      : super(key: key);

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final ProductController productController = Get.find();

  List<String> _recommendedStyles = [];
  List<dynamic> _recommendedProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    final result = await productController.getRecommendations(widget.faceShape);

    setState(() {
      _recommendedStyles = result['stylesRecommendées'];
      _recommendedProducts = result['products'];
      _error = result['error'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommandations pour ${widget.faceShape}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecommendations,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.face,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Conseils personnalisés pour ${widget.faceShape}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Affichage d'erreur si nécessaire
                    if (_error != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red[900]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Styles recommandés
                    Card(
                      margin: EdgeInsets.only(bottom: 20),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.style,
                                    color: Theme.of(context).primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Styles recommandés',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ..._recommendedStyles.map((style) => Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(style),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                    // Produits recommandés
                    if (_recommendedProducts.isNotEmpty)
                      _buildRecommendationSection(
                        context,
                        'Conseils',
                        _getGlassesRecommendations(widget.faceShape),
                        Icons.lightbulb,
                      ),
                    _buildProductSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Produits recommandés',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = _recommendedProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            product: product,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['imageUrl'] ??
                                  'https://via.placeholder.com/150',
                              height: 120,
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: 160,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error,
                                      color: Colors.grey[600]),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            product['name'] ?? 'Produit sans nom',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          SizedBox(height: 4),
                          Text(
                            product['style'] ?? 'Style non spécifié',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${product['price'] ?? '0'} TND',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            if (_recommendedProducts.length >= 5)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Naviguer vers une page de liste complète des produits
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ProductListScreen(
                    //       faceShape: widget.faceShape,
                    //       recommendedStyles: _recommendedStyles,
                    //     ),
                    //   ),
                    // );
                  },
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Voir tous les produits'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(
    BuildContext context,
    String title,
    List<String> recommendations,
    IconData icon,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...recommendations.map((recommendation) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(recommendation),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _getGlassesRecommendations(String faceShape) {
    switch (faceShape) {
      case 'Visage Carré':
        return [
          'Optez pour des montures rondes ou ovales pour adoucir les angles',
          'Les montures fines et légères peuvent atténuer la structure anguleuse',
          'Évitez les montures carrées qui accentuent les angles du visage',
          'Les montures colorées peuvent ajouter du contraste et de l\'intérêt'
        ];
      case 'Visage Rond':
        return [
          'Préférez les montures rectangulaires ou angulaires pour structurer le visage',
          'Les montures fines peuvent allonger visuellement le visage',
          'Évitez les montures rondes qui accentuent la forme du visage',
          'Les montures cat-eye peuvent ajouter de la définition au visage'
        ];
      case 'Visage Ovale':
        return [
          'Vous pouvez porter pratiquement tous les styles de montures',
          'Les montures oversize peuvent ajouter du caractère à votre visage',
          'Les montures géométriques peuvent créer un contraste intéressant',
          'Expérimentez avec différentes couleurs pour trouver ce qui vous convient'
        ];
      case 'Visage Rectangulaire':
        return [
          'Optez pour des montures rondes pour adoucir les angles',
          'Les montures avec un pont bas peuvent réduire la longueur du visage',
          'Évitez les montures trop rectangulaires qui allongent le visage',
          'Les montures colorées sur le dessus peuvent équilibrer les proportions'
        ];
      default:
        return [
          'Essayez différentes formes pour trouver celle qui vous va le mieux',
          'Consultez un opticien pour des conseils personnalisés',
          'Tenez compte de la taille de votre visage pour choisir la taille des montures',
          'Considérez votre style personnel et votre confort'
        ];
    }
  }
}
