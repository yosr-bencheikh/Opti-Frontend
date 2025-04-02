import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/UI/screens/User/optician_product_screen.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildOpticianCard(BuildContext context, dynamic optician) {
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
        // Header with image and favorite button
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            image: DecorationImage(
              image: AssetImage('assets/images/b1.jpeg'),
              fit: BoxFit.cover,
              // If you have actual store images, use:
              // image: optician.imageUrl != null
              //     ? NetworkImage(optician.imageUrl)
              //     : AssetImage('assets/images/store_placeholder.jpg'),
            ),
          ),
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            onPressed: () {
              // Toggle favorite status
              //opticianController.toggleFavorite(optician.id);
            },
          ),
        ),

        // Store information
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
                  SizedBox(width: 12),
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
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 4),
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

              // Rating and reviews
              SizedBox(height: 16),
              Row(
                children: [
                  // Rating stars
                  Row(
                    children: List.generate(5, (index) {
                      // Assume optician has a rating property, default to 4
                      int rating = /*optician.rating ??*/ 4;
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ),
                  SizedBox(width: 8),
                  // Review count
                  Text(
                    '(${/*optician.reviewCount ?? */ 24} Avis)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Contact info and actions
              SizedBox(height: 16),
              Row(
                children: [
                  // Phone button
                  // Inside _buildOpticianCard method, modify the phone button action:
                  // Replace the existing phone button onTap with this improved version
                  buildActionButton(
                    icon: Icons.phone,
                    label: 'Appeler',
                    color: Colors.green,
                    onTap: () async {
                      final rawNumber = optician.phone ?? '20767957';
                      final cleanedNumber =
                          rawNumber.replaceAll(RegExp(r'[^\d+]'), '');

                      if (cleanedNumber.isEmpty) {
                        showErrorSnackbar(
                            'Format de numéro de téléphone invalide');
                        return;
                      }

                      try {
                        final uri = Uri.parse('tel:$cleanedNumber');

                        // Verify app can handle the URL
                        if (!await launchUrl(uri)) {
                          showErrorSnackbar(
                              'Impossible de lancer le composeur');
                        }
                      } on PlatformException catch (e) {
                        showErrorSnackbar(
                            'Erreur de plateforme : ${e.message}');
                      } catch (e) {
                        showErrorSnackbar(
                            'Erreur inattendue : ${e.toString()}');
                      }
                    },
                  ),
                  SizedBox(width: 12),
                  // Directions button
                  // Directions button
                  // Directions button
                  buildActionButton(
                    icon: Icons.directions,
                    label: 'Directions',
                    color: Colors.blue,
                    onTap: () async {
                      try {
                        // Add null checks and empty validation
                        final rawAddress = optician.adresse?.trim() ?? '';

                        if (rawAddress.isEmpty) {
                          showErrorSnackbar(
                              'Adresse non disponible pour ce magasin');
                          debugPrint(
                              "Adresse manquante pour magasin d'optique : ${optician.id}");
                          return;
                        }

                        // Add debug output to verify the address
                        debugPrint(
                            "Tentative de navigation vers : $rawAddress");

                        final encodedAddress = Uri.encodeComponent(rawAddress);
                        final mapsUri = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');

                        if (await canLaunchUrl(mapsUri)) {
                          await launchUrl(mapsUri);
                        } else {
                          showErrorSnackbar(
                              "Impossible de lancer l'application de cartes");
                        }
                      } catch (e) {
                        showErrorSnackbar(
                            'Erreur de navigation : ${e.toString()}');
                        debugPrint("Détails de l'erreur de navigation : $e");
                      }
                    },
                  ),
                  SizedBox(width: 12),
                  // View store button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text(
                        'Voir les produits',
                        style: GoogleFonts.montserrat(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size(0, 36),
                      ),
                      onPressed: () {
                        if (optician.id != null) {
                          // Schedule navigation after the current build frame
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Get.to(() => OpticianProductsScreen(
                                opticianId: optician.id!));
                          });
                        } else {
                          showErrorSnackbar(
                              'Identifiant de l\'opticien non disponible');
                        }
                      },
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
}

Widget buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
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
    duration: Duration(seconds: 3),
  );
}
