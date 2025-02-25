import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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
  final ProductController productController = Get.find();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  List<Product> get _filteredProducts {
    if (_searchController.text.isEmpty) {
      return productController.products;
    }
    return productController.products.where((product) {
      final query = _searchController.text.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    body: Obx(() => // Utiliser Obx au lieu de ListenableBuilder
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
                onPressed: () {},
                icon: const Icon(Icons.file_download),
                label: const Text('Filtrer'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
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
    if (productController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productController.error != null) {
      return Center(
        child: Column(
          children: [
            Text('Erreur: ${productController.error}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => productController.loadProducts(),
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
                    onChanged: (value) => setState(
                        () {}), // Met à jour l'affichage des produits filtrés
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
            child: // ... previous imports and code remain the same ...

                DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              dataRowMaxHeight: 80,
              columns: const [
                DataColumn(
                  label: Text(
                    'Image',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Opticien',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nom',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Catégorie',
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
                    'Marque',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Couleur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Type de verre',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Prix',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Stock',
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
              rows: _filteredProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: product.image != null &&
                                product.image!.isNotEmpty
                            ? Image.network(
                                product.image!,
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
                     DataCell(Text(productController.getOpticienNom(product.opticienId) ?? 'N/A')),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(product.category)),
                    DataCell(Text(product.description)),
                    DataCell(Text(product.marque)),
                    DataCell(Text(product.couleur)),
                    DataCell(Text(product.typeVerre ?? 'N/A')),
                    DataCell(
                      Text(
                        '${product.prix.toStringAsFixed(2)} €',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
    image: '',
    typeVerre: '',
    opticienId: '',
  );

  showDialog(
    context: context,
    barrierDismissible: false, // Empêcher la fermeture en cliquant à l'extérieur
    builder: (context) => AlertDialog(
      title: const Text('Ajouter un produit'),
      content: _buildProductForm(formKey, product, isEditing: false),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              formKey.currentState?.save();
              
              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );

              // Ajouter le produit
              final success = await productController.addProduct(product);
              
              // Fermer l'indicateur de chargement
              Navigator.of(context).pop();
              
              if (success) {
                // Fermer le dialogue du formulaire
                Navigator.of(context).pop();
                
                // Afficher un message de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produit ajouté avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // Afficher un message d'erreur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${productController.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
                productController.updateProduct(product.id!, product);
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
            DropdownButtonFormField<String>(
              value: product.opticienId.isEmpty ? null : product.opticienId,
              decoration: const InputDecoration(labelText: 'Opticien'),
              items: productController.opticiens.map((opticien) {
                return DropdownMenuItem<String>(
                  value: opticien.id,
                  child: Text(opticien.nom),
                );
              }).toList(),
              validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              onChanged: (value) {
                if (value != null) {
                  product.opticienId = value;
                }
              },
            ),

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
              onSaved: (value) =>
                  product.quantiteStock = int.tryParse(value!) ?? 0,
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
                          : (product.image != null &&
                                  product.image!.isNotEmpty
                              ? Image.network(
                                  product.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                )
                              : const Icon(Icons.add_photo_alternate,
                                  size: 40)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _imageFile = File(pickedFile.path);
                            });
                            final image = await productController
                                .uploadImage(_imageFile!);
                            if (image != null) {
                              product.image = image;
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
              productController.deleteProduct(product.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}