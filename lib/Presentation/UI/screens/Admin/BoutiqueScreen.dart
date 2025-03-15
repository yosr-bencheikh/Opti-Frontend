import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/domain/entities/Boutique.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({Key? key}) : super(key: key);

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final BoutiqueController opticienController = Get.find();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
  }

  List<Opticien> get _filteredOpticiens {
    List<Opticien> filteredList = opticienController.opticiensList;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredList = filteredList.where((opticien) {
        return opticien.nom.toLowerCase().contains(query) ||
            opticien.adresse.toLowerCase().contains(query) ||
            opticien.ville.toLowerCase().contains(query) || // New field
            opticien.email.toLowerCase().contains(query) ||
            opticien.phone.toLowerCase().contains(query) ||
            opticien.description.toLowerCase().contains(query);
      }).toList();
    }

    return filteredList;
  }

  // Get paginated data
  List<Opticien> get _paginatedOpticiens {
    final filteredList = _filteredOpticiens;
    final startIndex = _currentPage * _itemsPerPage;

    if (startIndex >= filteredList.length) {
      return [];
    }

    final endIndex = (startIndex + _itemsPerPage < filteredList.length)
        ? startIndex + _itemsPerPage
        : filteredList.length;

    return filteredList.sublist(startIndex, endIndex);
  }

  int get _pageCount {
    return (_filteredOpticiens.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Calculer les indices pour l'affichage
    final startIndex =
        _filteredOpticiens.isEmpty ? 0 : _currentPage * _itemsPerPage + 1;
    final endIndex = _paginatedOpticiens.isEmpty
        ? 0
        : startIndex + _paginatedOpticiens.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Boutiques',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ajout du texte pour afficher le nombre de boutiques
                  Text(
                    '  ${_filteredOpticiens.length} boutiques',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddBoutiqueDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Nouveau boutique'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 84, 151, 198),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _currentPage = 0; // Reset to first page on search
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un boutique',
                prefixIcon: Icon(Icons.search,
                    color: Color.fromARGB(255, 84, 151, 198)),
                filled: true,
                fillColor: Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 84, 151, 198), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                hintStyle: TextStyle(color: Color(0xFF757575)),
              ),
              style: TextStyle(color: const Color(0xFF212121), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (opticienController.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
        ),
      );
    }

    if (opticienController.error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${opticienController.error}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => opticienController.getOpticien(),
              child: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7BD5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredOpticiens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucune boutique disponible'
                  : 'Aucune boutique ne correspond à votre recherche',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Effacer la recherche'),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    dataRowHeight: 72,
                    headingRowHeight: 56,
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    headingTextStyle: TextStyle(
                      color: const Color.fromARGB(255, 14, 14, 15),
                      fontWeight: FontWeight.bold,
                    ),
                    dividerThickness: 1,
                    showBottomBorder: true,
                    columns: const [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Adresse')),
                      DataColumn(label: Text('Ville')), // New column
                      DataColumn(label: Text('Téléphone')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Horaires')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _paginatedOpticiens.map((opticien) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              opticien.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                opticien.adresse,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                opticien
                                    .ville, // Add this line for the new column
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(opticien.phone)),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                opticien.email,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                opticien.description,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                opticien.opening_hours,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(_buildActionButtons(opticien)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _pageCount;

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage de ${_paginatedOpticiens.length} sur ${_filteredOpticiens.length} boutiques',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _currentPage > 0
                    ? () => setState(() {
                          _currentPage--;
                        })
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Précédent'),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_currentPage + 1} / $totalPages'),
              ),
              OutlinedButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() {
                          _currentPage++;
                        })
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Opticien opticien) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditBoutiqueDialog(context, opticien),
          tooltip: 'Modifier',
          color: const Color(0xFF3A7BD5),
          splashRadius: 24,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(context, opticien),
          tooltip: 'Supprimer',
          color: Colors.red[400],
          splashRadius: 24,
        ),
      ],
    );
  }

  void _showAddBoutiqueDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final descriptionController = TextEditingController();
    final openingHoursController = TextEditingController();
    final villeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ajouter une boutique',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          controller: nomController,
                          label: 'Nom',
                          hint: 'Entrez le nom de la boutique',
                          prefixIcon: Icons.store,
                          validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un nom';
                                      }
                                      return null;
                                    },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: adresseController,
                          label: 'Adresse',
                          hint: 'Entrez l\'adresse complète',
                          prefixIcon: Icons.location_on,
                            validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer une adresse';
                                      }
                                      return null;
                                    },
                        ),
                        _buildFormField(
                          controller: villeController,
                          label: 'Ville',
                          hint: 'Sélectionnez la ville',
                          prefixIcon: Icons.location_city,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isDropdown: true, // Indicate that this is a dropdown
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: phoneController,
                          label: 'Téléphone',
                          hint: '8 chiffres',
                          prefixIcon: Icons.phone,
                            validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un numéro de téléphone';
                                      }
                                      if (value.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                                        return 'Le téléphone doit contenir exactement 8 chiffres';
                                      }
                                      return null;
                                    },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Ex: contact@boutique.com',
                          prefixIcon: Icons.email,
                            validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un email';
                                }
                                if (!value.endsWith('@gmail.com')) {
                                  return 'L\'email doit être sous format @gmail.com';
                                }
                                return null;
                              },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Décrivez la boutique en quelques mots',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                        validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer une descriptionn';
                                      }
                                      return null;
                                    },
                        ),
                        const SizedBox(height: 16),
                      _buildFormField(
  controller: openingHoursController,
  label: 'Horaires d\'ouverture',
  hint: 'Ex: Lun-Ven: 9h-18h, Sam: 9h-12h',
  prefixIcon: Icons.access_time,
  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
  isSchedulePicker: true, // Activer le sélecteur d'horaires
),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        // Create a new Opticien with the form data
                        final opticien = Opticien(
                          id: '', // ID will be assigned by the server
                          nom: nomController.text,
                          adresse: adresseController.text,
                          ville: villeController.text, // New field
                          phone: phoneController.text,
                          email: emailController.text,
                          description: descriptionController.text,
                          opening_hours: openingHoursController.text,
                        );

                        // Close the dialog first to avoid context issues
                        Navigator.pop(dialogContext);

                        // Add the optician
                        final success =
                            await opticienController.addOpticien(opticien);

                        // Show a snackbar with the result
                        if (!context.mounted) return;
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Boutique ajoutée avec succès'
                                  : 'Erreur: ${opticienController.error.value}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {
                                scaffold.hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData prefixIcon,
  required String? Function(String?) validator,
  int maxLines = 1,
  bool isDropdown = false,
  bool isSchedulePicker = false, // Nouveau paramètre pour identifier le champ des horaires
}) {
  if (isDropdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: Regions.list.map((String region) {
            return DropdownMenuItem<String>(
              value: region,
              child: Text(region),
            );
          }).toList(),
          onChanged: (String? newValue) {
            controller.text = newValue ?? ''; // Mettre à jour le contrôleur
          },
        ),
      ],
    );
  } else if (isSchedulePicker) {
    // Cas spécifique pour le sélecteur d'horaires
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          readOnly: true, // Empêche la saisie manuelle
          onTap: () async {
            // Ouvrir le sélecteur d'horaires
            final selectedSchedule = await _showSchedulePicker();
            if (selectedSchedule != null) {
              controller.text = selectedSchedule; // Mettre à jour le contrôleur
            }
          },
          validator: validator,
        ),
      ],
    );
  } else {
    // Cas par défaut pour un TextFormField normal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: validator,
          maxLines: maxLines,
        ),
      ],
    );
  }
}
Future<String?> _showSchedulePicker() async {
  String selectedSchedule = '';
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Sélectionner les horaires'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélection des jours
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Jours',
                border: OutlineInputBorder(),
              ),
              items: ['Lun-Ven', 'Lun-Sam', 'Lun-Dim'].map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                selectedSchedule = '$value: ';
              },
            ),
            SizedBox(height: 16),
            // Sélection des heures d'ouverture
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.blue),
              title: Text(
                openingTime == null
                    ? 'Heure d\'ouverture'
                    : 'Ouverture: ${openingTime?.format(context)}',
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  openingTime = time;
                  selectedSchedule += '${time.format(context)}-';
                }
              },
            ),
            SizedBox(height: 8),
            // Sélection des heures de fermeture
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.red),
              title: Text(
                closingTime == null
                    ? 'Heure de fermeture'
                    : 'Fermeture: ${closingTime?.format(context)}',
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  closingTime = time;
                  selectedSchedule += time.format(context);
                }
              },
            ),
            // Validation des heures
            if (openingTime != null && closingTime != null)
              Text(
                closingTime!.hour < openingTime!.hour
                    ? 'L\'heure de fermeture doit être après l\'heure d\'ouverture'
                    : '',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (openingTime == null || closingTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez sélectionner les heures')),
                );
              } else if (closingTime!.hour < openingTime!.hour) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('L\'heure de fermeture doit être après l\'heure d\'ouverture'),
                  ),
                );
              } else {
                Navigator.pop(context, selectedSchedule);
              }
            },
            child: Text('Valider', style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );

  return selectedSchedule;
}

  void _showEditBoutiqueDialog(BuildContext context, Opticien opticien) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: opticien.nom);
    final adresseController = TextEditingController(text: opticien.adresse);
    final phoneController = TextEditingController(text: opticien.phone);
    final emailController = TextEditingController(text: opticien.email);
    final descriptionController =
        TextEditingController(text: opticien.description);
    final openingHoursController =
        TextEditingController(text: opticien.opening_hours);
    final villeController = TextEditingController(text: opticien.ville);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifier la boutique',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          controller: nomController,
                          label: 'Nom',
                          hint: 'Entrez le nom de la boutique',
                          prefixIcon: Icons.store,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: adresseController,
                          label: 'Adresse',
                          hint: 'Entrez l\'adresse complète',
                          prefixIcon: Icons.location_on,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                        ),
                            _buildFormField(
                          controller: villeController,
                          label: 'Ville',
                          hint: 'Sélectionnez la ville',
                          prefixIcon: Icons.location_city,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isDropdown: true, // Indicate that this is a dropdown
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                                    controller: phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Téléphone',
                                      border: OutlineInputBorder(),
                                      hintText: '8 chiffres',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un numéro de téléphone';
                                      }
                                      if (value.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                                        return 'Le téléphone doit contenir exactement 8 chiffres';
                                      }
                                      return null;
                                    },
                                  ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Ex: contact@boutique.com',
                          prefixIcon: Icons.email,
                          validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un email';
                                }
                                if (!value.endsWith('@gmail.com')) {
                                  return 'L\'email doit être sous format @gmail.com';
                                }
                                return null;
                              },
                            ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Décrivez la boutique en quelques mots',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                          validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer une description';
                                      }
                                      return null;
                                    },
                        ),
                        const SizedBox(height: 16),
            _buildFormField(
              controller: openingHoursController,
              label: 'Horaires d\'ouverture',
              hint: 'Ex: Lun-Ven: 9h-18h, Sam: 9h-12h',
              prefixIcon: Icons.access_time,
              validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              isSchedulePicker: true, // Activer le sélecteur d'horaires
            ),
                                  ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        // Create updated Opticien with form data
                        final updatedOpticien = Opticien(
                          id: opticien.id,
                          nom: nomController.text,
                          adresse: adresseController.text,
                          ville: villeController.text, // New field
                          phone: phoneController.text,
                          email: emailController.text,
                          description: descriptionController.text,
                          opening_hours: openingHoursController.text,
                        );

                        // Close the dialog first to avoid context issues
                        Navigator.pop(dialogContext);

                        // Update the optician
                        final success = await opticienController.updateOpticien(
                            opticien.id, updatedOpticien);

                        // Show a snackbar with the result
                        if (!context.mounted) return;
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Boutique mise à jour avec succès'
                                  : 'Erreur: ${opticienController.error.value}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {
                                scaffold.hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mettre à jour',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Opticien opticien) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${opticien.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Close the dialog first to avoid context issues
              Navigator.pop(dialogContext);

              // Delete the optician
              final success =
                  await opticienController.deleteOpticien(opticien.id);

              // Show a snackbar with the result
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Boutique supprimée avec succès'
                      : 'Erreur: ${opticienController.error.value}'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
