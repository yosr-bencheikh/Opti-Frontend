import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/optician_product_screen.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class StoresScreen extends StatelessWidget {
  final NavigationController navigationController = Get.find();
  final BoutiqueController opticianController = Get.find();
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
            hintText: 'Find optical stores...',
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
            'Filter Opticians',
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
                      'Address',
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
                      hint: 'Select address',
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
                      'City',
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
                      hint: 'Select city',
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
                'Show favorites only',
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
                  'Apply',
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
    // Assuming each optician has a city property
    // If not available, you can extract city from address or add a dummy list
    return ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice']; // Example
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
            (optician.adresse != null &&
                optician.adresse.toLowerCase() ==
                    selectedCity.value.toLowerCase());

        // Favorites filter (assume there's a favorites property or method)
        //final matchesFavorite = !showFavoritesOnly.value || optician.isFavorite;

        return matchesName && matchesAddress && matchesCity;
      }).toList();

      if (filteredOpticians.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                'No opticians match your search',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try different search terms or reset filters',
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
              'Optician ${index + 1}: ${optician.nom} - ${optician.adresse}');
          return _buildOpticianCard(context, optician);
        },
      );
    });
  }

  Widget _buildOpticianCard(BuildContext context, dynamic optician) {
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
                      '(${/*optician.reviewCount ?? */ 24} reviews)',
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
                    _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      color: Colors.green,
                      onTap: () async {
                        final rawNumber = optician.telephone ?? '20767957';
                        final cleanedNumber =
                            rawNumber.replaceAll(RegExp(r'[^\d+]'), '');

                        if (cleanedNumber.isEmpty) {
                          _showErrorSnackbar('Invalid phone number format');
                          return;
                        }

                        try {
                          final uri = Uri.parse('tel:$cleanedNumber');

                          // Verify app can handle the URL
                          if (!await launchUrl(uri)) {
                            _showErrorSnackbar('Could not launch dialer');
                          }
                        } on PlatformException catch (e) {
                          _showErrorSnackbar('Platform error: ${e.message}');
                        } catch (e) {
                          _showErrorSnackbar(
                              'Unexpected error: ${e.toString()}');
                        }
                      },
                    ),
                    SizedBox(width: 12),
                    // Directions button
                    // Directions button
                    // Directions button
                    _buildActionButton(
                      icon: Icons.directions,
                      label: 'Directions',
                      color: Colors.blue,
                      onTap: () async {
                        try {
                          // Add null checks and empty validation
                          final rawAddress = optician.adresse?.trim() ?? '';

                          if (rawAddress.isEmpty) {
                            _showErrorSnackbar(
                                'Address not available for this store');
                            debugPrint(
                                'Missing address for optician ID: ${optician.id}');
                            return;
                          }

                          // Add debug output to verify the address
                          debugPrint('Attempting to navigate to: $rawAddress');

                          final encodedAddress =
                              Uri.encodeComponent(rawAddress);
                          final mapsUri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');

                          if (await canLaunchUrl(mapsUri)) {
                            await launchUrl(mapsUri);
                          } else {
                            _showErrorSnackbar(
                                'Could not launch maps application');
                          }
                        } catch (e) {
                          _showErrorSnackbar(
                              'Navigation error: ${e.toString()}');
                          debugPrint('Navigation error details: $e');
                        }
                      },
                    ),
                    SizedBox(width: 12),
                    // View store button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text(
                          'View Products',
                          style: GoogleFonts.montserrat(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size(0, 36),
                        ),
                        onPressed: () {
                          // Navigate to optician details
                          Get.to(() =>
                              OpticianProductsScreen(opticianId: optician.id));
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

  Widget _buildActionButton({
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
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
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
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: Duration(seconds: 3),
    );
  }
}
