import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductController _controller;
 final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  TextEditingController _searchController = TextEditingController();

// Pagination variables
  int _itemsPerPage = 10;
  int _currentPage = 0;
  
  // Filter variables
  String? _selectedCategory;
  String? _selectedBrand;
  RangeValues _priceRange = RangeValues(0, 1000);
  bool _showFilters = false;

@override
void initState() {
  super.initState();
  _controller = ProductController(ProductDatasource());
  _controller.loadProducts().then((_) {
    if (_controller.products.isNotEmpty) {
      final maxPrice = _controller.products
          .map((p) => p.prix)
          .reduce((max, price) => price > max ? price : max);
      setState(() {
        _priceRange = RangeValues(0, maxPrice);
      });
    }
  });
}
List<Product> get _filteredProducts {
  print('Filtering products...');
  print('Search text: ${_searchController.text}');
  print('Selected category: $_selectedCategory');
  print('Selected brand: $_selectedBrand');
  print('Price range: ${_priceRange.start} - ${_priceRange.end}');

  return _controller.products.where((product) {
    final matchesSearch = _searchController.text.isEmpty || 
      [
        product.name,
        product.category,
        product.description,
        product.marque,
        product.couleur,
        product.typeVerre,
        product.prix.toString(),
        product.quantiteStock.toString()
      ].any((field) => 
        field?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false
      );

    final matchesCategory = _selectedCategory == null || 
      product.category == _selectedCategory;

    final matchesBrand = _selectedBrand == null || 
      product.marque == _selectedBrand;

    final matchesPrice = product.prix >= _priceRange.start && 
      product.prix <= _priceRange.end;

    return matchesSearch && matchesCategory && matchesBrand && matchesPrice;
  }).toList();
}
List<Product> get _paginatedProducts {
  final startIndex = _currentPage * _itemsPerPage;
  final endIndex = startIndex + _itemsPerPage;
  final filteredList = _filteredProducts;
  
  if (startIndex >= filteredList.length) {
    return [];
  }
  
  return filteredList.sublist(
    startIndex,
    endIndex > filteredList.length ? filteredList.length : endIndex
  );
}
 Widget _buildFilters() {
    if (!_showFilters) return const SizedBox.shrink();

    final categories = _controller.products
        .map((p) => p.category)
        .toSet()
        .toList();
    
    final brands = _controller.products
        .map((p) => p.marque)
        .toSet()
        .toList();

    final maxPrice = _controller.products
        .map((p) => p.prix)
        .reduce((max, price) => price > max ? price : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Toutes les catégories'),
              ),
              ...categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBrand,
            decoration: const InputDecoration(
              labelText: 'Marque',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Toutes les marques'),
              ),
              ...brands.map((brand) => DropdownMenuItem(
                value: brand,
                child: Text(brand),
              )),
            ],
            onChanged: (value) => setState(() => _selectedBrand = value),
          ),
          const SizedBox(height: 16),
          const Text('Plage de prix'),
          RangeSlider(
            values: _priceRange,
            max: maxPrice,
            divisions: 20,
            labels: RangeLabels(
              '${_priceRange.start.round()}€',
              '${_priceRange.end.round()}€',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _selectedCategory = null;
                  _selectedBrand = null;
                  _priceRange = RangeValues(0, maxPrice);
                }),
                child: const Text('Réinitialiser'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => setState(() => _showFilters = false),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
  final pageCount = (_filteredProducts.length / _itemsPerPage).ceil();
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _currentPage > 0
            ? () => setState(() => _currentPage--)
            : null,
      ),
      Text('${_currentPage + 1} / $pageCount'),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: _currentPage < pageCount - 1
            ? () => setState(() => _currentPage++)
            : null,
      ),
      const SizedBox(width: 16),
      DropdownButton<int>(
        value: _itemsPerPage,
        items: [10, 20, 50, 100].map((value) => DropdownMenuItem(
          value: value,
          child: Text('$value par page'),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _itemsPerPage = value;
              _currentPage = 0;
            });
          }
        },
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (_showFilters) _buildFilters(),
              if (_showFilters) const SizedBox(height: 24),
              _buildContent(),
              const SizedBox(height: 16),
              _buildPagination(),
            ],
          ),
        );
      },
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
            'Produits',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2A2A),
            ),
          ),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                label: Text(_showFilters ? 'Masquer les filtres' : 'Filtrer'),
                style: FilledButton.styleFrom(
                  backgroundColor: _showFilters ? Colors.grey : Colors.white,
                  foregroundColor: _showFilters ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showAddProductDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 113, 160, 201),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildContent() {
  if (_controller.isLoading.value) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_controller.error.value != null) {
    return Center(
      child: Column(
        children: [
          Text('Erreur: ${_controller.error.value}'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _controller.loadProducts(),
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
                  onChanged: (value) => setState(() {}), // Force rebuild
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
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
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Catégorie')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Marque')),
              DataColumn(label: Text('Couleur')),
              DataColumn(label: Text('Type de verre')),
              DataColumn(label: Text('Prix')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _paginatedProducts.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ),
                  DataCell(Text(product.name)),
                  DataCell(Text(product.category)),
                  DataCell(Text(product.description)),
                  DataCell(Text(product.marque)),
                  DataCell(Text(product.couleur)),
                  DataCell(Text(product.typeVerre ?? 'N/A')),
                  DataCell(Text('${product.prix.toStringAsFixed(2)} €')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.quantiteStock > 0
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.quantiteStock.toString(),
                        style: TextStyle(
                          color: product.quantiteStock > 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(_buildActionButtons(product)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildActionButtons(Product product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditProductDialog(context, product),
          tooltip: 'Modifier',
          color: Colors.grey[700],
        ),
        IconButton(
          icon: const Icon(Icons.link),
          onPressed: () {},
          tooltip: 'Copier le lien',
          color: Colors.grey[700],
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(context, product),
          tooltip: 'Supprimer',
          color: Colors.red[400],
        ),
      ],
    );
  }
  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    Product product = Product(
      name: '',
      description: '',
      category: '',
      marque: '',
      couleur: '',
      prix: 0,
      quantiteStock: 0,
      imageUrl: '',
      typeVerre: '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un produit'),
        content: _buildProductForm(formKey, product, isEditing: false),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                _controller.addProduct(product);
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le produit'),
        content: _buildProductForm(formKey, product, isEditing: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                _controller.updateProduct(product.id!, product);
                Navigator.pop(context);
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
Widget _buildProductForm(GlobalKey<FormState> formKey, Product product,
      {required bool isEditing}) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: product.name,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.name = value ?? '',
            ),
            TextFormField(
              initialValue: product.prix.toString(),
              decoration: const InputDecoration(labelText: 'Prix'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Champ requis';
                if (double.tryParse(value!) == null) return 'Prix invalide';
                return null;
              },
              onSaved: (value) => product.prix = double.tryParse(value!) ?? 0,
            ),
            TextFormField(
              initialValue: product.quantiteStock.toString(),
              decoration: const InputDecoration(labelText: 'Quantité en stock'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Champ requis';
                if (int.tryParse(value!) == null) return 'Quantité invalide';
                return null;
              },
              onSaved: (value) => product.quantiteStock = int.tryParse(value!) ?? 0,
            ),
            TextFormField(
              initialValue: product.category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.category = value ?? '',
            ),
            TextFormField(
              initialValue: product.marque,
              decoration: const InputDecoration(labelText: 'Marque'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.marque = value ?? '',
            ),
            TextFormField(
              initialValue: product.couleur,
              decoration: const InputDecoration(labelText: 'Couleur'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.couleur = value ?? '',
            ),
            TextFormField(
              initialValue: product.description,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.description = value ?? '',
            ),
            Column(
              children: [
                const Text('Image du produit', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          )
                        : (product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              )
                            : const Icon(Icons.add_photo_alternate, size: 40)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _imageFile = File(pickedFile.path);
                            });
                            final imageUrl = await _controller.uploadImage(_imageFile!);
                            if (imageUrl != null) {
                              product.imageUrl = imageUrl;
                            }
                          }
                        },
                        icon: const Icon(Icons.edit),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
            TextFormField(
              initialValue: product.typeVerre,
              decoration: const InputDecoration(labelText: 'Type de verre'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
              onSaved: (value) => product.typeVerre = value ?? '',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${product.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteProduct(product.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}