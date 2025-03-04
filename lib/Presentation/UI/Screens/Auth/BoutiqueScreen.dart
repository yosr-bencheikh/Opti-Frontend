import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opti_app/Presentation/controllers/opticien_controller.dart';
import 'package:opti_app/domain/entities/Opticien.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({Key? key}) : super(key: key);

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final OpticienController opticienController = Get.find();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  TextEditingController _searchController = TextEditingController();
  
  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
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
      backgroundColor: Colors.grey[100],
      body: Obx(() =>
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Boutiques',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2A2A),
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showAddBoutiqueDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: FilledButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 113, 160, 201),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (opticienController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (opticienController.error.isNotEmpty) {
      return Center(
        child: Column(
          children: [
            Text('Erreur: ${opticienController.error}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => opticienController.getOpticien(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _currentPage = 0; // Reset to first page on search
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une boutique...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              dataRowMaxHeight: 80,
              columns: const [
                DataColumn(
                  label: Text(
                    'Nom',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Adresse',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Téléphone',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Horaires',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _paginatedOpticiens.map((opticien) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opticien.nom,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(opticien.adresse)),
                    DataCell(Text(opticien.phone)),
                    DataCell(Text(opticien.email)),
                    DataCell(Text(opticien.description)),
                    DataCell(Text(opticien.opening_hours)),
                    DataCell(_buildActionButtons(opticien)),
                  ],
                );
              }).toList(),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
  
  Widget _buildPagination() {
    final totalPages = _pageCount;
    
    if (totalPages <= 1) {
      return Container();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() {
                      _currentPage--;
                    })
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          Text('${_currentPage + 1} / $totalPages'),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() {
                      _currentPage++;
                    })
                : null,
            icon: const Icon(Icons.chevron_right),
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
          color: Colors.grey[700],
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(context, opticien),
          tooltip: 'Supprimer',
          color: Colors.red[400],
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter une boutique'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Champ requis';
                    if (!GetUtils.isEmail(value!)) return 'Email invalide';
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: openingHoursController,
                  decoration: const InputDecoration(labelText: 'Horaires d\'ouverture'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Create a new Opticien with the form data
                final opticien = Opticien(
                  id: '',  // ID will be assigned by the server
                  nom: nomController.text,
                  adresse: adresseController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  description: descriptionController.text,
                  opening_hours: openingHoursController.text,
                );
                
                // Close the dialog first to avoid context issues
                Navigator.pop(dialogContext);
                
                // Add the optician
                final success = await opticienController.addOpticien(opticien);
                
                // Show a snackbar with the result
                final scaffold = ScaffoldMessenger.of(context);
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Boutique ajoutée avec succès' 
                      : 'Erreur: ${opticienController.error.value}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showEditBoutiqueDialog(BuildContext context, Opticien opticien) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: opticien.nom);
    final adresseController = TextEditingController(text: opticien.adresse);
    final phoneController = TextEditingController(text: opticien.phone);
    final emailController = TextEditingController(text: opticien.email);
    final descriptionController = TextEditingController(text: opticien.description);
    final openingHoursController = TextEditingController(text: opticien.opening_hours);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier la boutique'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Champ requis';
                    if (!GetUtils.isEmail(value!)) return 'Email invalide';
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: openingHoursController,
                  decoration: const InputDecoration(labelText: 'Horaires d\'ouverture'),
                  validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Create updated Opticien with form data
                final updatedOpticien = Opticien(
                  id: opticien.id,
                  nom: nomController.text,
                  adresse: adresseController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  description: descriptionController.text,
                  opening_hours: openingHoursController.text,
                );
                
                // Close the dialog first to avoid context issues
                Navigator.pop(dialogContext);
                
                // Update the optician
                final success = await opticienController.updateOpticien(opticien.id, updatedOpticien);
                
                // Show a snackbar with the result
                final scaffold = ScaffoldMessenger.of(context);
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Boutique mise à jour avec succès' 
                      : 'Erreur: ${opticienController.error.value}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
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
              final success = await opticienController.deleteOpticien(opticien.id);
              
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