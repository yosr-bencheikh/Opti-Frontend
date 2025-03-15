import 'dart:io';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
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
    final AuthController _authController = Get.find<AuthController>();
 String _selectedNom = '';
  String _selectedPrenom = '';
  String _selectedDate = '';
  List<Optician> _filteredOpticians = [];
  String _currentSearchTerm = '';
  bool _showFilters = false;
  int _currentPage = 1;
  int _opticiansPerPage = 5;
  String? _sortColumn;
  bool _sortAscending = true;
  String? _highlightedOpticianId;
  String _selectedRegion = 'Toutes les régions';
String _selectedGenre = 'Tous les genres';
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
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
    // Filtrage par recherche textuelle générale
    final matchesSearch = _currentSearchTerm.isEmpty ||
        optician.nom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
        optician.prenom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
        optician.email.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
        optician.phone.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
        optician.region.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
        optician.date.contains(_currentSearchTerm);

    // Filtrage par région et genre
    final matchesRegion = _selectedRegion == 'Toutes les régions' || 
        optician.region == _selectedRegion;

    final matchesGenre = _selectedGenre == 'Tous les genres' || 
        optician.genre == _selectedGenre;
    
    // Nouveaux filtres: nom, prénom et date
    final matchesNom = _selectedNom.isEmpty || 
        optician.nom.toLowerCase().contains(_selectedNom.toLowerCase());
    
    final matchesPrenom = _selectedPrenom.isEmpty || 
        optician.prenom.toLowerCase().contains(_selectedPrenom.toLowerCase());
    
    final matchesDate = _selectedDate.isEmpty || 
        optician.date.contains(_selectedDate);

    // Retourner true seulement si tous les filtres sont satisfaits
    return matchesSearch && matchesRegion && matchesGenre && 
           matchesNom && matchesPrenom && matchesDate;
  }).toList();

  // Appliquer le tri si une colonne est sélectionnée
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
      }
      
      return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
  }

}

void _updateFilters(String region, String genre) {
  setState(() {
    _selectedRegion = region;
    _selectedGenre = genre;
    _filterOpticians(); 
  });
}
  void _showSnackBar(String message, {bool isError = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
Future<String> _uploadImageAndGetUrl(PlatformFile? imageFile, String email) async {
  if (imageFile == null) {
    return '';
  }

  try {
    if (kIsWeb) {
      // For web, use the bytes of the image
      if (imageFile.bytes != null) {
        final imageUrl = await _controller.uploadImageWeb(
          imageFile.bytes!,
          imageFile.name,
          email,
        );
        return imageUrl;
      }
    } else {
      // For mobile, use the file path
      final file = File(imageFile.path!);
      final imageUrl = await _controller.uploadImage(file, email);
      return imageUrl;
    }

    return '';
  } catch (e) {
    print('Error uploading image: $e');
    _showSnackBar('Erreur de téléchargement de l\'image: ${e.toString()}', isError: true);
    return '';
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
  PlatformFile? _tempSelectedImage;
  final List<String> genres = ['Homme', 'Femme'];
  String selectedGenre = optician?.genre ?? genres.first;
  DateTime _selectedDate = DateTime.tryParse(optician?.date ?? '') ?? DateTime.now();
  String _selectedRegion = optician?.region ?? Regions.list.first;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              optician == null ? 'Ajouter un opticien' : 'Modifier un opticien',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile image upload section
                    Center(
                      child: Column(
                        children: [
                          FilePickerExample(
                            onImagePicked: (PlatformFile? file) {
                              setState(() {
                                _tempSelectedImage = file;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text('Photo de profil'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            readOnly: true,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une date';
                              }

                              // Vérifier que l'utilisateur a au moins 13 ans
                              final selectedDate = DateTime.tryParse(value);
                              if (selectedDate != null) {
                                final today = DateTime.now();
                                final age = today.year - selectedDate.year -
                                    (today.month < selectedDate.month ||
                                            (today.month == selectedDate.month && today.day < selectedDate.day)
                                        ? 1
                                        : 0);

                                if (age < 13) {
                                  return 'L\'utilisateur doit avoir au moins 13 ans';
                                }
                              }
                              return null;
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
                              setState(() {
                                selectedGenre = newValue!;
                                _genreController.text = newValue;
                              });
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
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                        hintText: 'Minimum 8 caractères avec majuscule, chiffre et caractère spécial',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins une majuscule';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un chiffre';
                        }
                        if (!RegExp(r'[!@/+_#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un caractère spécial';
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        hintText: 'exemple@gmail.com',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Région',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                                  _regionController.text = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
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
    try {
      final newOptician = Optician(
        id: optician?.id,
        nom: _nameController.text,
        prenom: _prenomController.text,
        date: _dateController.text,
        genre: selectedGenre,
        password: _passwordController.text,
        address: _addressController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        region: _selectedRegion,
        imageUrl: _imageUrlController.text,
      );
      Navigator.pop(context);

      if (optician == null) {
        await _controller.addOptician(newOptician);
      } else {
        await _controller.updateOptician(newOptician);
      }

      if (_tempSelectedImage != null) {
        final imageUrl = await _uploadImageAndGetUrl(
          _tempSelectedImage,
          _emailController.text,
        );
        newOptician.imageUrl = imageUrl;
        await _controller.updateOptician(newOptician);
      }

      if (optician == null) {
        final completeUser = await _authController.getUserByEmail(newOptician.email);
        newOptician.id = completeUser['_id'] ?? completeUser['id'] ?? '';
      }

      Get.snackbar(
        'Succès', 
        optician == null ? 'Opticien ajouté avec succès' : 'Opticien modifié avec succès'
      );

      // Fermer la boîte de dialogue
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar('Erreur', 'Une erreur s\'est produite: ${e.toString()}');
      print('Erreur détaillée: $e'); // Ajoutez ceci pour déboguer
    }
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
        }
      );
    },
  );
}
Widget _buildAdvancedFilters() {
  final List<String> regions = [
    'Toutes les régions',
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Le Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Medenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kebili',
  ];
  final List<String> genres = ['Tous les genres', 'Homme', 'Femme'];
  
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
                value: _selectedRegion,
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
                    _selectedRegion = newValue!;
                    _filterOpticians();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGenre,
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
                    _selectedGenre = newValue!;
                    _filterOpticians();
                  });
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
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedNom = value;
                    _filterOpticians();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedPrenom = value;
                    _filterOpticians();
                  });
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
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'AAAA-MM-JJ',
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedDate = value;
                    _filterOpticians();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(), // Espace vide pour équilibrer le layout
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRegion = 'Toutes les régions';
                  _selectedGenre = 'Tous les genres';
                  _selectedNom = '';
                  _selectedPrenom = '';
                  _selectedDate = '';
                  _filterOpticians();
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
                _filterOpticians();
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
                        label: const Text('Date de naissance'),
                        onSort: (_, __) => _sortByField('date'),
                      ),
                      DataColumn(
                        label: const Text('Téléphone'),
                        onSort: (_, __) => _sortByField('phone'),
                      ),
                        DataColumn(
                        label: const Text('Genre'),
                        onSort: (_, __) => _sortByField('genre'),
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
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                optician.date,
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
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                optician.genre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 13, 13, 13)
                                ),
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

  Future<void> _showEditOpticianDialog(Optician optician) async {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  PlatformFile? _tempSelectedImage;

  // Créer des contrôleurs avec les données existantes de l'opticien
  final TextEditingController _nameController = TextEditingController(text: optician.nom);
  final TextEditingController _prenomController = TextEditingController(text: optician.prenom);
  final TextEditingController _dateController = TextEditingController(text: optician.date);
  final TextEditingController _passwordController = TextEditingController(text: optician.password);
  final TextEditingController _addressController = TextEditingController(text: optician.address);
  final TextEditingController _emailController = TextEditingController(text: optician.email);
  final TextEditingController _phoneController = TextEditingController(text: optician.phone);
  final TextEditingController _statusController = TextEditingController(text: optician.status);

  // Valeurs pour les menus déroulants
  String _selectedRegion = Regions.list.contains(optician.region) ? optician.region : Regions.list[0];
  String _selectedGenre = ['Homme', 'Femme'].contains(optician.genre) ? optician.genre : 'Homme';
  DateTime _selectedDate = DateTime.tryParse(optician.date) ?? DateTime.now();

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            'Modifier un opticien',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          content: Container(
            width: 600,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Section de l'image de profil
                    Center(
                      child: Column(
                        children: [
                          FilePickerExample(
                            onImagePicked: (PlatformFile? file) {
                              setState(() {
                                _tempSelectedImage = file;
                              });
                            },
                            initialImageUrl: optician.imageUrl,
                          ),
                          const SizedBox(height: 8),
                          const Text('Photo de profil'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations personnelles - Nom et Prénom
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

                    // Date de naissance et Genre
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            readOnly: true,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une date';
                              }

                              // Vérifier que l'utilisateur a au moins 13 ans
                              final selectedDate = DateTime.tryParse(value);
                              if (selectedDate != null) {
                                final today = DateTime.now();
                                final age = today.year - selectedDate.year -
                                    (today.month < selectedDate.month ||
                                            (today.month == selectedDate.month && today.day < selectedDate.day)
                                        ? 1
                                        : 0);

                                if (age < 13) {
                                  return 'L\'utilisateur doit avoir au moins 13 ans';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGenre,
                            decoration: InputDecoration(
                              labelText: 'Genre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            items: ['Homme', 'Femme'].map((String genre) {
                              return DropdownMenuItem<String>(
                                value: genre,
                                child: Text(genre),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedGenre = newValue;
                                });
                              }
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

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                        hintText: 'Minimum 8 caractères avec majuscule, chiffre et caractère spécial',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins une majuscule';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un chiffre';
                        }
                        if (!RegExp(r'[!@/+_#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un caractère spécial';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Adresse
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

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        hintText: 'exemple@gmail.com',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                    SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
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
                    SizedBox(height: 16),

                    // Région
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Région',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une région';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Statut (si nécessaire)
                    // Vous pouvez ajouter le champ de statut ici si nécessaire
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        // Démarrez le chargement
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          // Créer un opticien mis à jour
                          Optician updatedOptician = Optician(
                            id: optician.id,
                            nom: _nameController.text,
                            prenom: _prenomController.text,
                            date: _dateController.text,
                            genre: _selectedGenre,
                            password: _passwordController.text,
                            address: _addressController.text,
                            email: _emailController.text,
                            phone: _phoneController.text,
                            region: _selectedRegion,
                            imageUrl: optician.imageUrl, // Valeur par défaut
                            status: _statusController.text,
                          );

                          // Si une nouvelle image est sélectionnée, téléchargez-la
                          if (_tempSelectedImage != null) {
                            final imageUrl = await _uploadImageAndGetUrl(
                              _tempSelectedImage,
                              _emailController.text,
                            );
                            // Mettez à jour l'URL de l'image de l'opticien
                            updatedOptician.imageUrl = imageUrl;
                          }

                          // Mettez à jour l'opticien dans la base de données
                          await _controller.updateOptician(updatedOptician);

                          // Affichez un message de succès
                          Get.snackbar(
                            'Succès', 
                            'Opticien modifié avec succès',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );

                          // Fermez la boîte de dialogue
                          Navigator.pop(dialogContext);
                          
                          // Forcez le rafraîchissement de l'interface utilisateur
                          if (mounted) {
                            setState(() {
                              // Rafraichir la liste des opticiens
                              _controller.fetchOpticians();
                            });
                          }
                        } catch (e) {
                          // Affichez un message d'erreur
                          Get.snackbar(
                            'Erreur', 
                            'Une erreur s\'est produite: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        );
      },
    ),
  );

  if (mounted) {
    setState(() {});
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des Opticiens',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
              '${_controller.getTotalOpticians()} Opticiens',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
             onChanged: (value) => _onSearchChanged(),
            decoration: InputDecoration(
                    hintText: 'Rechercher un opticien',
                    prefixIcon: Icon(Icons.search, color:  Color.fromARGB(255, 84, 151, 198)),
                    filled: true,
                    fillColor: Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color.fromARGB(255, 84, 151, 198), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    hintStyle: TextStyle(color: Color(0xFF757575)),
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