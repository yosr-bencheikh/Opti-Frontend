import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/UI/screens/User/optician_product_screen.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/store_wishlist_controller.dart';
import 'package:opti_app/Presentation/widgets/opticalstoreCard.dart';
import 'package:url_launcher/url_launcher.dart';

class StoresScreen extends StatelessWidget {
  final NavigationController navigationController = Get.find();
  final BoutiqueController opticianController = Get.find();
  final StoreWishlistController wishlistController =
      Get.find<StoreWishlistController>();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedAddress = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxBool showFavoritesOnly = false.obs;
  final RxBool isFilterExpanded = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Advanced Filter Section
          Obx(() => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: isFilterExpanded.value ? null : 0,
                child: isFilterExpanded.value
                    ? _buildAdvancedFilters(context)
                    : SizedBox(),
              )),

          // Main Content
          Expanded(child: _buildOpticalStores()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) => searchQuery.value = value,
          decoration: InputDecoration(
            hintText: "Trouver des magasins d'optique...",
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            prefixIcon:
                Icon(Icons.search, color: Colors.blue.shade700, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        Obx(
          () => IconButton(
            icon: Icon(
              isFilterExpanded.value
                  ? Icons.filter_list
                  : Icons.filter_list_off,
              color: isFilterExpanded.value
                  ? Colors.blue.shade700
                  : Colors.grey.shade600,
            ),
            onPressed: () {
              isFilterExpanded.value = !isFilterExpanded.value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Title
          Text(
            "Filtrer les magasins d'optique",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),

          // Location Filters
          Row(
            children: [
              // Address Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adresse',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildFilterDropdown(
                      value: selectedAddress.value.isEmpty
                          ? null
                          : selectedAddress.value,
                      hint: 'Selectionner adresse',
                      items: _getUniqueAddresses(),
                      onChanged: (value) {
                        selectedAddress.value = value ?? '';
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // City Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ville',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildFilterDropdown(
                      value: selectedCity.value.isEmpty
                          ? null
                          : selectedCity.value,
                      hint: 'Selectionner ville',
                      items: _getUniqueCities(),
                      onChanged: (value) {
                        selectedCity.value = value ?? '';
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Favorites Switch
          Row(
            children: [
              Text(
                'Afficher la liste des favoris seulement',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Obx(() => Switch(
                    value: showFavoritesOnly.value,
                    activeColor: Colors.blue.shade700,
                    onChanged: (value) {
                      showFavoritesOnly.value = value;
                    },
                  )),
            ],
          ),
          SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  selectedAddress.value = '';
                  selectedCity.value = '';
                  showFavoritesOnly.value = false;
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade700),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.montserrat(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  isFilterExpanded.value = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Appliquer',
                  style: GoogleFonts.montserrat(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        value: value,
        isExpanded: true,
        hint: Text(hint),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.montserrat(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  List<String> _getUniqueAddresses() {
    return opticianController.opticiensList
        .map((optician) => optician.adresse)
        .toSet()
        .toList();
  }

  List<String> _getUniqueCities() {
    // Use a case-insensitive approach to avoid duplicates that differ only in case
    final Set<String> uniqueCities = {};

    for (var optician in opticianController.opticiensList) {
      if (optician.ville != null && optician.ville.isNotEmpty) {
        uniqueCities.add(optician.ville.trim());
      }
    }

    return uniqueCities.toList()..sort(); // Sort for better user experience
  }

  Widget _buildOpticalStores() {
    return Obx(() {
      if (opticianController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredOpticians =
          opticianController.opticiensList.where((optician) {
        // Name filter
        final matchesName = optician.nom
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase());

        // Address filter
        final matchesAddress = selectedAddress.value.isEmpty ||
            optician.adresse.toLowerCase() ==
                selectedAddress.value.toLowerCase();

        // City filter
        final matchesCity = selectedCity.value.isEmpty ||
            (optician.ville != null &&
                optician.ville.toLowerCase() ==
                    selectedCity.value.toLowerCase());

        // Favorites filter
        final matchesFavorite = !showFavoritesOnly.value ||
            wishlistController.isFavorite(optician.id);

        return matchesName && matchesAddress && matchesCity && matchesFavorite;
      }).toList();

      if (filteredOpticians.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                "Aucun magasins d'optique ne correspond à votre recherche",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Essayez différents termes de recherche ou réinitialisez les filtres',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOpticians.length,
        itemBuilder: (context, index) {
          final optician = filteredOpticians[index];
          debugPrint(
              "magasin d'optique ${index + 1}: ${optician.nom} - ${optician.adresse}");
          return buildOpticianCard(context, optician);
        },
      );
    });
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isSelected: false,
              onTap: () => navigationController.changePage(0),
            ),
            _buildNavItem(
              icon: Icons.store,
              label: 'Stores',
              isSelected: true,
              onTap: () => {},
            ),
            _buildNavItem(
              icon: (Icons.list_alt),
              label: 'Commandes',
              isSelected: false,
              onTap: () => navigationController.changePage(2),
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              isSelected: false,
              onTap: () => navigationController.changePage(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: Duration(seconds: 3),
    );
  }
}
