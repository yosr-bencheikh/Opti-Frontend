import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:flutter/services.dart';

class OpticianScreen extends StatefulWidget {
  final String? selectedOpticianId;
  const OpticianScreen({Key? key, this.selectedOpticianId}) : super(key: key);

  @override
  _OpticianScreenState createState() => _OpticianScreenState();
}

class _OpticianScreenState extends State<OpticianScreen> {
  final OpticianController _controller = Get.put(OpticianController());
  final TextEditingController _searchController = TextEditingController();
  List<Optician> _filteredOpticians = [];
  String _currentSearchTerm = '';
  bool _showFilters = false;
  int _currentPage = 1;
  int _opticiansPerPage = 10;
  String? _sortColumn;
  bool _sortAscending = true;
  String? _highlightedOpticianId;

  @override
  void initState() {
    super.initState();
    _controller.fetchOpticians();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchTerm = _searchController.text;
      _filterOpticians();
      _currentPage = 1; // Reset to first page on new search
    });
  }

  void _filterOpticians() {
    if (_controller.opticians.isEmpty) {
      _filteredOpticians = [];
      return;
    }

    _filteredOpticians = _controller.opticians.where((optician) {
      final matchesSearch = _currentSearchTerm.isEmpty ||
          optician.nom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          optician.prenom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          optician.email.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          optician.phone.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          optician.region.toLowerCase().contains(_currentSearchTerm.toLowerCase());

      return matchesSearch;
    }).toList();

    // Apply sorting if a column is selected
    if (_sortColumn != null) {
      _filteredOpticians.sort((a, b) {
        var aValue = '';
        var bValue = '';
        
        switch (_sortColumn) {
          case 'nom':
            aValue = a.nom;
            bValue = b.nom;
            break;
          case 'prenom':
            aValue = a.prenom;
            bValue = b.prenom;
            break;
          case 'email':
            aValue = a.email;
            bValue = b.email;
            break;
          case 'phone':
            aValue = a.phone;
            bValue = b.phone;
            break;
          case 'region':
            aValue = a.region;
            bValue = b.region;
            break;
          case 'date':
            aValue = a.date;
            bValue = b.date;
            break;
          case 'genre':
            aValue = a.genre;
            bValue = b.genre;
            break;
          case 'status':
            aValue = a.status;
            bValue = b.status;
            break;
        }
        
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      });
    }
  }

  void _showOpticianDialog({Optician? optician}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController(text: optician?.nom);
    final TextEditingController _prenomController = TextEditingController(text: optician?.prenom);
    final TextEditingController _dateController = TextEditingController(text: optician?.date);
    final TextEditingController _genreController = TextEditingController(text: optician?.genre);
    final TextEditingController _passwordController = TextEditingController(text: optician?.password);
    final TextEditingController _addressController = TextEditingController(text: optician?.address);
    final TextEditingController _emailController = TextEditingController(text: optician?.email);
    final TextEditingController _phoneController = TextEditingController(text: optician?.phone);
    final TextEditingController _regionController = TextEditingController(text: optician?.region);
    final TextEditingController _imageUrlController = TextEditingController(text: optician?.imageUrl);
    final TextEditingController _statusController = TextEditingController(text: optician?.status);

    // Ajout des genres prédéfinis
    final List<String> genres = ['Homme', 'Femme', 'Autre'];
    String selectedGenre = optician?.genre ?? genres.first;
    
    // Ajout des statuts prédéfinis
    final List<String> statuses = ['Actif', 'Inactif', 'En congé', 'En formation'];
    String selectedStatus = optician?.status ?? statuses.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(optician == null ? 'Ajouter un opticien' : 'Modifier un opticien', 
                     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _prenomController,
                          decoration: InputDecoration(
                            labelText: 'Prénom',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un prénom';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Date de naissance',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une date';
                            }
                            return null;
                          },
                          onTap: () async {
                            // Add date picker here if needed
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGenre,
                          decoration: InputDecoration(
                            labelText: 'Genre',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          items: genres.map((String genre) {
                            return DropdownMenuItem<String>(
                              value: genre,
                              child: Text(genre),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            selectedGenre = newValue!;
                            _genreController.text = newValue;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner un genre';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      } else if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une adresse';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email';
                      } else if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un téléphone';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _regionController,
                    decoration: InputDecoration(
                      labelText: 'Région',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une région';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL de l\'image',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: statuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedStatus = newValue!;
                      _statusController.text = newValue;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newOptician = Optician(
                    id: optician?.id,
                    nom: _nameController.text,
                    prenom: _prenomController.text,
                    date: _dateController.text,
                    genre: _genreController.text,
                    password: _passwordController.text,
                    address: _addressController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    region: _regionController.text,
                    imageUrl: _imageUrlController.text,
                    status: _statusController.text,
                  );

                  if (optician == null) {
                    await _controller.addOptician(newOptician);
                    Get.snackbar('Succès', 'Opticien ajouté avec succès');
                  } else {
                    await _controller.updateOptician(newOptician);
                    Get.snackbar('Succès', 'Opticien modifié avec succès');
                  }

                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(optician == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilters() {
    final List<String> regions = ['Toutes les régions', 'Tunis', 'Sfax', 'Sousse', 'Monastir', 'Ariana'];
    final List<String> genres = ['Tous les genres', 'Homme', 'Femme', 'Autre'];
    final List<String> statuses = ['Tous les statuts', 'Actif', 'Inactif', 'En congé', 'En formation'];
    
    String selectedRegion = 'Toutes les régions';
    String selectedGenre = 'Tous les genres';
    String selectedStatus = 'Tous les statuts';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Filtres avancés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'Région',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: regions.map((String region) {
                    return DropdownMenuItem<String>(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRegion = newValue!;
                      // Apply filter
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedGenre,
                  decoration: InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: genres.map((String genre) {
                    return DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGenre = newValue!;
                      // Apply filter
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: statuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                      // Apply filter
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Reset filters
                  setState(() {
                    selectedRegion = 'Toutes les régions';
                    selectedGenre = 'Tous les genres';
                    selectedStatus = 'Tous les statuts';
                  });
                },
                icon: Icon(Icons.clear, size: 18),
                label: Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Apply filters
                },
                icon: Icon(Icons.check, size: 18),
                label: Text('Appliquer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
  return Obx(() {
    if (_controller.isLoading.value) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
            ),
            SizedBox(height: 16),
            Text('Chargement en cours...',
                style: TextStyle(fontSize: 16, color: Colors.grey))
          ],
        ),
      );
    }
    
    if (_controller.error.isNotEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
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
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Une erreur est survenue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.error.value,
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _controller.fetchOpticians(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BD5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Filter opticians based on search
    _filterOpticians();
    
    if (_filteredOpticians.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'Aucun opticien disponible'
                    : 'Aucun opticien ne correspond à votre recherche',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Effacer la recherche'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3A7BD5),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final displayedOpticians = _filteredOpticians.length <= _opticiansPerPage
        ? _filteredOpticians
        : _filteredOpticians.sublist(
            (_currentPage - 1) * _opticiansPerPage,
            _currentPage * _opticiansPerPage > _filteredOpticians.length 
                ? _filteredOpticians.length 
                : _currentPage * _opticiansPerPage,
          );

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
                    headingTextStyle: const TextStyle(
                      color: Color.fromARGB(255, 14, 14, 15),
                      fontWeight: FontWeight.bold,
                    ),
                    dividerThickness: 1,
                    showBottomBorder: true,
                    columns: [
                      const DataColumn(label: Text('ID')),
                      const DataColumn(label: Text('Opticien')),
                      DataColumn(
                        label: const Text('Nom'),
                        onSort: (_, __) => _sortByField('nom'),
                      ),
                      DataColumn(
                        label: const Text('Prénom'),
                        onSort: (_, __) => _sortByField('prenom'),
                      ),
                      DataColumn(
                        label: const Text('Email'),
                        onSort: (_, __) => _sortByField('email'),
                      ),
                      DataColumn(
                        label: const Text('Téléphone'),
                        onSort: (_, __) => _sortByField('phone'),
                      ),
                      DataColumn(
                        label: const Text('Région'),
                        onSort: (_, __) => _sortByField('region'),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: displayedOpticians.map((optician) {
                      final isSelected = optician.id == _highlightedOpticianId;
                      
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (isSelected) {
                              return Colors.blue.shade50;
                            }
                            if (displayedOpticians.indexOf(optician) % 2 == 0) {
                              return Colors.grey.shade50;
                            }
                            return Colors.white;
                          },
                        ),
                        cells: [
                          DataCell(Text(optician.id ?? 'N/A',
                              style: const TextStyle(color: Color.fromARGB(255, 11, 11, 11)))),
                          DataCell(
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: optician.imageUrl != null && optician.imageUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(optician.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.blue.shade100,
                              ),
                              child: optician.imageUrl == null || optician.imageUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        '${optician.prenom.isNotEmpty ? optician.prenom[0] : ''}${optician.nom.isNotEmpty ? optician.nom[0] : ''}',
                                        style: const TextStyle(
                                          color: Color(0xFF3A7BD5),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          DataCell(
                            Text(
                              optician.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color.fromARGB(255, 11, 11, 11)
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              optician.prenom,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 16, 16, 16)
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                optician.email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 13, 13, 13)
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              optician.phone,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 9, 9, 9)
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                optician.region,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF3A7BD5)),
                                  onPressed: () => _showEditOpticianDialog(optician),
                                  tooltip: 'Modifier',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirmation'),
                                          content: const Text('Voulez-vous vraiment supprimer cet opticien ?'),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Annuler'),
                                            ),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.delete, size: 18),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () {
                                                if (optician.id != null) {
                                                  _controller.deleteOptician(optician.id!);
                                                } else {
                                                  Get.snackbar(
                                                    'Erreur', 
                                                    'Impossible de supprimer un opticien sans ID',
                                                    snackPosition: SnackPosition.BOTTOM,
                                                    backgroundColor: Colors.red.shade100,
                                                    colorText: Colors.red.shade900,
                                                    margin: const EdgeInsets.all(16),
                                                    borderRadius: 8,
                                                  );
                                                }
                                                Navigator.pop(context);
                                              },
                                              label: const Text('Supprimer'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  tooltip: 'Supprimer',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.teal),
                                  onPressed: () => _showOpticianDetails(optician),
                                  tooltip: 'Détails',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (_filteredOpticians.length > _opticiansPerPage)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: const Text('Précédent'),
                      onPressed: _currentPage > 1
                          ? () => setState(() {
                                _currentPage--;
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3A7BD5),
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        'Page $_currentPage / ${(_filteredOpticians.length / _opticiansPerPage).ceil()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      label: const Text('Suivant'),
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: _currentPage < (_filteredOpticians.length / _opticiansPerPage).ceil()
                          ? () => setState(() {
                                _currentPage++;
                              })
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A7BD5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  });
}

// Méthode pour afficher les détails d'un opticien
void _showOpticianDetails(Optician optician) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: optician.imageUrl != null && optician.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(optician.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.blue.shade100,
                    ),
                    child: optician.imageUrl == null || optician.imageUrl!.isEmpty
                        ? Center(
                            child: Text(
                              '${optician.prenom.isNotEmpty ? optician.prenom[0] : ''}${optician.nom.isNotEmpty ? optician.nom[0] : ''}',
                              style: const TextStyle(
                                color: Color(0xFF3A7BD5),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${optician.prenom} ${optician.nom}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${optician.id ?? 'N/A'} • ${optician.region}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.phone, 'Téléphone', optician.phone),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.email, 'Email', optician.email),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.map, 'Région', optician.region),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditOpticianDialog(optician);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper pour construire une ligne de détails
Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    ],
  );
}

  void _showEditOpticianDialog(Optician optician) {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: optician.nom);
  final TextEditingController _prenomController = TextEditingController(text: optician.prenom);
  final TextEditingController _dateController = TextEditingController(text: optician.date);
  final TextEditingController _genreController = TextEditingController(text: optician.genre);
  final TextEditingController _passwordController = TextEditingController(text: optician.password);
  final TextEditingController _addressController = TextEditingController(text: optician.address);
  final TextEditingController _emailController = TextEditingController(text: optician.email);
  final TextEditingController _phoneController = TextEditingController(text: optician.phone);
  final TextEditingController _regionController = TextEditingController(text: optician.region);
  final TextEditingController _imageUrlController = TextEditingController(text: optician.imageUrl);
  final TextEditingController _statusController = TextEditingController(text: optician.status);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Modifier un opticien'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prénom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une date';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _genreController,
                  decoration: const InputDecoration(labelText: 'Genre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un genre';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true, // Masquer le mot de passe
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un téléphone';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(labelText: 'Région'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une région';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL de l\'image'),
                ),
                TextFormField(
                  controller: _statusController,
                  decoration: const InputDecoration(labelText: 'Statut'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final updatedOptician = Optician(
                  id: optician.id,
                  nom: _nameController.text,
                  prenom: _prenomController.text,
                  date: _dateController.text,
                  genre: _genreController.text,
                  password: _passwordController.text,
                  address: _addressController.text,
                  email: _emailController.text,
                  phone: _phoneController.text,
                  region: _regionController.text,
                  imageUrl: _imageUrlController.text,
                  status: _statusController.text,
                );
                await _controller.updateOptician(updatedOptician);
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Opticiens'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.fetchOpticians(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un opticien...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_showFilters) _buildAdvancedFilters(),
          Expanded(
            child: _buildContent(),
          ),
          // Pagination
          if (_filteredOpticians.length > _opticiansPerPage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage de ${(_filteredOpticians.length / _opticiansPerPage).ceil()}',
                    style: TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: _currentPage < (_filteredOpticians.length / _opticiansPerPage).ceil()
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOpticianDialog,
        child: Icon(Icons.add),
        tooltip: 'Ajouter un opticien',
      ),
    );
  }
  
  void _sortByField(String column) {
    setState(() {
      // If clicking the same column, toggle direction
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }
}