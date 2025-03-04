import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:http/http.dart' as http;

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserController _controller = UserController(UserDataSourceImpl(client: http.Client()));
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  // Pagination
  int _currentPage = 1;
  int _usersPerPage = 10;
  int get _startIndex => (_currentPage - 1) * _usersPerPage;
  int get _endIndex => _startIndex + _usersPerPage > _filteredUsers.length 
      ? _filteredUsers.length 
      : _startIndex + _usersPerPage;
  
  // Search and filtering
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];
  String _currentSearchTerm = '';
  String _sortColumn = '';
  bool _sortAscending = true;
  
  // Advanced filters
  Map<String, String?> _filters = {
    'nom': null,
    'prenom': null,
    'email': null,
    'date': null,
    'phone': null,
    'region': null,
    'genre': null,
  };
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
    
    // Add listener to searchController
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
      _filterUsers();
      _currentPage = 1; // Reset to first page on new search
    });
  }
  
  void _filterUsers() {
    if (_controller.users.isEmpty) {
      _filteredUsers = [];
      return;
    }
    
    _filteredUsers = _controller.users.where((user) {
      // Global search
      final matchesSearch = _currentSearchTerm.isEmpty ||
      user.nom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.nom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.prenom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.email.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.phone.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.date.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.region.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.genre.toLowerCase().contains(_currentSearchTerm.toLowerCase());
      
      // Advanced filters check
      final matchesNom = _filters['nom'] == null || _filters['nom']!.isEmpty ||
          user.nom.toLowerCase().contains(_filters['nom']!.toLowerCase());
          
      final matchesPrenom = _filters['prenom'] == null || _filters['prenom']!.isEmpty ||
          user.prenom.toLowerCase().contains(_filters['prenom']!.toLowerCase());
          
      final matchesEmail = _filters['email'] == null || _filters['email']!.isEmpty ||
          user.email.toLowerCase().contains(_filters['email']!.toLowerCase());
          
      final matchesPhone = _filters['phone'] == null || _filters['phone']!.isEmpty ||
          user.phone.toLowerCase().contains(_filters['phone']!.toLowerCase());
          
      final matchesDate = _filters['date'] == null || _filters['date']!.isEmpty ||
          user.date.toLowerCase().contains(_filters['date']!.toLowerCase());
          
      final matchesRegion = _filters['region'] == null || _filters['region']!.isEmpty ||
          user.region == _filters['region'];
          
      final matchesGenre = _filters['genre'] == null || _filters['genre']!.isEmpty ||
          user.genre == _filters['genre'];
      
      return matchesSearch && matchesNom && matchesPrenom && matchesEmail 
          && matchesPhone && matchesDate && matchesRegion && matchesGenre;
    }).toList();
    
    // Apply sorting if a column is selected
    if (_sortColumn.isNotEmpty) {
      _filteredUsers.sort((a, b) {
        var aValue = _getValueForSort(a, _sortColumn);
        var bValue = _getValueForSort(b, _sortColumn);
        
        var comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      });
    }
  }
  
  String _getValueForSort(User user, String column) {
    switch (column) {
      case 'id': return user.id ?? '';
      case 'nom': return user.nom.toLowerCase();
      case 'prenom': return user.prenom.toLowerCase();
      case 'email': return user.email.toLowerCase();
      case 'date': return user.date;
      case 'phone': return user.phone;
      case 'region': return user.region.toLowerCase();
      case 'genre': return user.genre.toLowerCase();
      default: return '';
    }
  }
  
  void _sortBy(String column) {
    setState(() {
      // If clicking the same column, toggle direction
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _filterUsers();
    });
  }
  
  void _resetFilters() {
    setState(() {
      for (var key in _filters.keys) {
        _filters[key] = null;
      }
      _filterUsers();
      _currentPage = 1;
    });
  }

  Future<void> _loadUsers() async {
    await _controller.fetchUsers();
    setState(() {
      _filterUsers();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(child: Text(_controller.error!));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            if (_showFilters) _buildAdvancedFilters(),
            const SizedBox(height: 16),
            _buildContent(),
            const SizedBox(height: 16),
            _buildPagination(),
          ],
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
            'Utilisateurs',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2A2A),
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showAddUserDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un utilisateur'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 113, 160, 201),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                label: Text(_showFilters ? 'Masquer filtres' : 'Filtres avancés'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showFilters ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text('${_filteredUsers.length} utilisateur${_filteredUsers.length != 1 ? 's' : ''} trouvé${_filteredUsers.length != 1 ? 's' : ''}'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Réinitialiser les filtres'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedFilters() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // First row of filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters['nom'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                  controller: TextEditingController(text: _filters['nom']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters['prenom'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                  controller: TextEditingController(text: _filters['prenom']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters['email'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                  controller: TextEditingController(text: _filters['email']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Second row of filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters['phone'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                  controller: TextEditingController(text: _filters['phone']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    border: OutlineInputBorder(),
                    hintText: 'YYYY-MM-DD',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters['date'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                  controller: TextEditingController(text: _filters['date']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Région',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Toutes les régions'),
                  value: _filters['region'],
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les régions'),
                    ),
                    ...Regions.list.map((region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters['region'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Tous les genres'),
                  value: _filters['genre'],
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les genres'),
                    ),
                    ...['Homme', 'Femme', 'Autre'].map((genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters['genre'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Handle empty state
    if (_filteredUsers.isEmpty) {
      return Container(
        height: 300,
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    
    // Get current page users
    final displayedUsers = _filteredUsers.length <= _usersPerPage 
        ? _filteredUsers 
        : _filteredUsers.sublist(_startIndex, _endIndex);
    
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
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        dataRowHeight: 70,
        headingRowHeight: 56,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade100, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        columns: [
          DataColumn(
            label: const Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          DataColumn(
            label: const Text('Image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          DataColumn(
            label: const Text('Nom', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('nom'),
          ),
          DataColumn(
            label: const Text('Prénom', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('prenom'),
          ),
          DataColumn(
            label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('email'),
          ),
          DataColumn(
            label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('date'),
          ),
          DataColumn(
            label: const Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('phone'),
          ),
          DataColumn(
            label: const Text('Région', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('region'),
          ),
          DataColumn(
            label: const Text('Genre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            onSort: (_, __) => _sortBy('genre'),
          ),
          const DataColumn(
            label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
        rows: displayedUsers.map((user) {
          return DataRow(
            color: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (displayedUsers.indexOf(user) % 2 == 0) {
                  return Colors.blue.shade50.withOpacity(0.3);
                }
                return Colors.white;
              },
            ),
            cells: [
              DataCell(Text(user.id ?? 'N/A', style: const TextStyle(color: Colors.blue))),  // Afficher l'ID
              DataCell(
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: user.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(user.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                    color: Colors.grey[200],
                  ),
                  child: user.imageUrl.isEmpty
                    ? Center(
                        child: Text(
                          '${user.nom.isNotEmpty ? user.nom[0] : ''}${user.prenom.isNotEmpty ? user.prenom[0] : ''}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                ),
              ),
              DataCell(Text(user.nom, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.prenom, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.email, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.date, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.phone, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.region, style: const TextStyle(color: Colors.blue))),
              DataCell(Text(user.genre, style: const TextStyle(color: Colors.blue))),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(user),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(user),
                    tooltip: 'Supprimer',
                  ),
                ],
              )),
            ],
          );
        }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPagination() {
    if (_filteredUsers.isEmpty || _filteredUsers.length <= _usersPerPage) {
      return const SizedBox.shrink();
    }
    
    final int totalPages = (_filteredUsers.length / _usersPerPage).ceil();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Displaying range and total
          Text(
            'Affichage de ${_startIndex + 1} à $_endIndex sur ${_filteredUsers.length} utilisateurs',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          
          // Page size selector
          Row(
            children: [
              const Text('Lignes par page: '),
              DropdownButton<int>(
                value: _usersPerPage,
                items: [5, 10, 20, 50, 100].map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _usersPerPage = value;
                      // Adjust current page if needed
                      int maxPage = (_filteredUsers.length / _usersPerPage).ceil();
                      if (_currentPage > maxPage) {
                        _currentPage = maxPage;
                      }
                    });
                  }
                },
              ),
            ],
          ),
          
          // Pagination controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 
                    ? () => setState(() => _currentPage = 1) 
                    : null,
                tooltip: 'Première page',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _currentPage > 1 
                    ? () => setState(() => _currentPage--) 
                    : null,
                tooltip: 'Page précédente',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _currentPage < totalPages 
                    ? () => setState(() => _currentPage++) 
                    : null,
                tooltip: 'Page suivante',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages 
                    ? () => setState(() => _currentPage = totalPages) 
                    : null,
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
      ),
    );
  }


Future<void> _showAddUserDialog() async {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Selection variables
  String _selectedRegion = Regions.list.first;
  String _selectedGenre = 'Homme';
  DateTime _selectedDate = DateTime.now();
  File? _tempSelectedImage;

  // Format initial date
  _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: Container(
            width: 600,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile image upload section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (image != null) {
                                setState(() {
                                  _tempSelectedImage = File(image.path);
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                image: _tempSelectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_tempSelectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _tempSelectedImage == null
                                  ? const Icon(Icons.add_a_photo, size: 40)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Photo de profil'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name and surname fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un nom';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _prenomController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(),
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
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone and date fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un numéro de téléphone';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != _selectedDate) {
                                setState(() {
                                  _selectedDate = picked;
                                  _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(
                                  labelText: 'Date de naissance',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez sélectionner une date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Region and gender selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Région',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedRegion,
                            items: Regions.list.map((region) {
                              return DropdownMenuItem(
                                value: region,
                                child: Text(region),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Genre',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedGenre,
                            items: ['Homme', 'Femme', 'Autre'].map((genre) {
                              return DropdownMenuItem(
                                value: genre,
                                child: Text(genre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGenre = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  try {
                    // Create the new user first (without image)
                    final newUser = User(
                      nom: _nomController.text,
                      prenom: _prenomController.text,
                      email: _emailController.text,
                      date: _dateController.text,
                      region: _selectedRegion,
                      genre: _selectedGenre,
                      password: _passwordController.text,
                      phone: _phoneController.text,
                      status: 'Active',
                      imageUrl: '', // Initially empty
                    );

                    // Add user first
                    await _controller.addUser(newUser);

                    setState(() {
        _controller.users.add(newUser);
      });
                    
                    // Then upload image if selected
                    if (_tempSelectedImage != null) {
                      try {
                        String imageUrl = await _controller.uploadImage(_tempSelectedImage!, _emailController.text);
                        print('Uploaded image URL: $imageUrl');
                      } catch (imageError) {
                        print('Image upload error: ${imageError.toString()}');
                        // Don't fail the whole operation if image upload fails
                      }
                    }

                    // Show success message
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur ajouté avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    // Reload the user list
                    await _loadUsers();

                    // Close the dialog
                    Navigator.pop(context);
                  } catch (e) {
                    // Show error message
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    ),
  );
}
  Future<void> _showEditDialog(User user) async {
  final _formKey = GlobalKey<FormState>();

  // Initialize controllers with existing user data
  final TextEditingController _nomController = TextEditingController(text: user.nom);
  final TextEditingController _prenomController = TextEditingController(text: user.prenom);
  final TextEditingController _emailController = TextEditingController(text: user.email);
  final TextEditingController _phoneController = TextEditingController(text: user.phone);
  final TextEditingController _dateController = TextEditingController(text: user.date);

  // Initialize selected values
  String _selectedRegion = user.region;
  String _selectedGenre = user.genre;
  DateTime _selectedDate = DateTime.tryParse(user.date) ?? DateTime.now();
  File? _tempSelectedImage;

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: Container(
            width: 600,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile image section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (image != null) {
                                setState(() {
                                  _tempSelectedImage = File(image.path);
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                image: _tempSelectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_tempSelectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : user.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(user.imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: (_tempSelectedImage == null && user.imageUrl.isEmpty)
                                  ? Center(
                                      child: Text(
                                        '${user.nom[0]}${user.prenom[0]}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Photo de profil'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name and surname fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un nom';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _prenomController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(),
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
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone and date fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un numéro de téléphone';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != _selectedDate) {
                                setState(() {
                                  _selectedDate = picked;
                                  _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(
                                  labelText: 'Date de naissance',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez sélectionner une date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Region and gender selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Région',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedRegion,
                            items: Regions.list.map((region) {
                              return DropdownMenuItem(
                                value: region,
                                child: Text(region),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Genre',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedGenre,
                            items: ['Homme', 'Femme', 'Autre'].map((genre) {
                              return DropdownMenuItem(
                                value: genre,
                                child: Text(genre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGenre = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  try {
                    // Update user object with new values
                    user.nom = _nomController.text;
                    user.email = _emailController.text;
                    
                    // Create updated user object
                    User updatedUser = User(
                      nom: _nomController.text,
                      prenom: _prenomController.text,
                      email: _emailController.text,
                      date: _dateController.text,
                      region: _selectedRegion,
                      genre: _selectedGenre,
                      password: user.password, // Keep the existing password
                      phone: _phoneController.text,
                      status: user.status,
                      imageUrl: user.imageUrl,
                      refreshTokens: user.refreshTokens,
                    );
                    
                    // Update the user first
                    await _controller.updateUser(updatedUser);
                    
                    // Handle image upload if a new image was selected
                    if (_tempSelectedImage != null) {
                      try {
                        String imageUrl = await _controller.uploadImage(_tempSelectedImage!, _emailController.text);
                        print('Updated image URL: $imageUrl');
                      } catch (imageError) {
                        print('Image upload error: ${imageError.toString()}');
                        // Don't fail the whole operation if image upload fails
                      }
                    }
                    
                    // Show success message
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur modifié avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Refresh the user list
                    await _loadUsers();
                    
                    // Close the dialog
                    Navigator.pop(context);
                  } catch (e) {
                    // Show error message
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    ),
  );
}
  Future<void> _showDeleteDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.nom}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _controller.deleteUser(user.email);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}