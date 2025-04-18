import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/UI/screens/User/OpticianReviewsScreen.dart';
import 'package:opti_app/Presentation/UI/screens/User/optician_product_screen.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/store_wishlist_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class OpticianCardWrapper extends StatefulWidget {
  final dynamic optician;

  const OpticianCardWrapper({Key? key, required this.optician})
      : super(key: key);

  @override
  State<OpticianCardWrapper> createState() => _OpticianCardWrapperState();
}

class _OpticianCardWrapperState extends State<OpticianCardWrapper> {
  final StoreWishlistController wishlistController = Get.find();
  final BoutiqueController boutiqueController = Get.find();
  final _statsLoaded = <String, bool>{};

  @override
  void initState() {
    super.initState();
    if (widget.optician.id != null) {
      wishlistController.initOpticianFavoriteStatus(widget.optician.id);
      _loadInitialStats();
    }
  }

  void _loadInitialStats() {
    if (!_statsLoaded.containsKey(widget.optician.id)) {
      _statsLoaded[widget.optician.id] = true;
      // Load stats and make sure to listen for updates
      boutiqueController.loadBoutiqueStats(widget.optician.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardContent(context, widget.optician);
  }

  Widget _buildCardContent(BuildContext context, dynamic optician) {
    // Use GetBuilder instead of Obx to ensure updates when boutiqueController updates
    return GetBuilder<BoutiqueController>(
      builder: (controller) {
        final isFavorite = wishlistController.isFavorite(optician.id);
        final avgRating = controller.getAverageRating(optician.id);
        final totalReviews = controller.getTotalReviews(optician.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/b1.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Obx(() => IconButton(
                      icon: Icon(
                        wishlistController.isFavorite(optician.id) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        color: wishlistController.isFavorite(optician.id) 
                            ? Colors.red 
                            : Colors.white,
                        size: 28,
                      ),
                      onPressed: () =>
                          wishlistController.toggleFavorite(optician.id),
                    )),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.store, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                optician.nom,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      optician.adresse,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _navigateToReviews(optician.id),
                      child: Row(
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '($totalReviews Avis)',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.phone,
                          label: 'Appeler',
                          color: Colors.green,
                          onTap: () => _makePhoneCall(optician.phone),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: 'Directions',
                          color: Colors.blue,
                          onTap: () => _openMaps(optician.adresse),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: Text(
                              'Voir les produits',
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 36),
                            ),
                            onPressed: () => _viewProducts(optician.id),
                          ),
                        ),
                      ],
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

  // Helper methods
  void _navigateToReviews(String? id) {
    if (id == null) {
      showErrorSnackbar('Identifiant non disponible');
      return;
    }
    Get.to(() => OpticianReviewsScreen(boutiqueId: id));
  }

  Future<void> _makePhoneCall(String? number) async {
    final cleanNumber =
        (number ?? '20767957').replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.isEmpty) {
      showErrorSnackbar('Numéro invalide');
      return;
    }
    try {
      final uri = Uri.parse('tel:$cleanNumber');
      if (!await launchUrl(uri)) showErrorSnackbar('Appel impossible');
    } catch (e) {
      showErrorSnackbar('Erreur: $e');
    }
  }

  Future<void> _openMaps(String? address) async {
    final rawAddress = address?.trim() ?? '';
    if (rawAddress.isEmpty) {
      showErrorSnackbar('Adresse non disponible');
      return;
    }
    try {
      final uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(rawAddress)}');
      if (!await launchUrl(uri)) showErrorSnackbar('Ouvrir carte impossible');
    } catch (e) {
      showErrorSnackbar('Erreur: $e');
    }
  }

  void _viewProducts(String? id) {
    if (id == null) {
      showErrorSnackbar('ID non disponible');
      return;
    }
    Get.to(() => OpticianProductsScreen(opticianId: id));
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: const Duration(seconds: 3),
    );
  }
}

Widget buildOpticianCard(BuildContext context, dynamic optician) {
  return OpticianCardWrapper(optician: optician);
}
