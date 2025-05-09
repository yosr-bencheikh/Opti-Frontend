import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/data/data_sources/storeReview_data_source.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';

class BoutiqueController extends GetxController {
  final BoutiqueRepository boutiqueRepository;
  final OpticianController opticianController;
  final StoreReviewDataSource _dataSource = StoreReviewDataSource();
  final isLoading = false.obs;
  final opticiensList = <Boutique>[].obs;
  final error = RxString('');
  final _statsCache = <String, Map<String, dynamic>>{}.obs;
  final _loadingStats = <String, bool>{}.obs;
  final selectedBoutique = Rx<Boutique?>(null);
  final RxList<Optician> _opticiens = <Optician>[].obs;
  final RxBool _showOnlyUserBoutiques = false.obs;
  final RxMap<String, dynamic> boutiquesStats = <String, dynamic>{}.obs;
    bool get isloading => isLoading.value;
  String? get _error => error.value;

  BoutiqueController(this.opticianController,
      {required this.boutiqueRepository});

  @override
  void onInit() {
    super.onInit();
    ever(opticianController.isLoggedIn, _handleAuthChange);
    if (opticianController.isLoggedIn.value) _loadBoutiquesForCurrentUser();
    loadInitialData();
  }

  void _handleAuthChange(bool isLoggedIn) {
    if (isLoggedIn) _loadBoutiquesForCurrentUser();
  }

  void _loadBoutiquesForCurrentUser() {
    final userId = opticianController.currentUserId.value;
    if (userId.isNotEmpty) getboutiqueByOpticianId(userId);
  }

  Future<void> loadInitialData() async {
    try {
      
      await (opticianController.isLoggedIn.value
          ? getboutiqueByOpticianId(opticianController.currentUserId.value)
          : getboutique());
    } catch (e) {
      error.value = e.toString();
    }
  }

  double getAverageRating(String boutiqueId) =>
      (_statsCache[boutiqueId]?['averageRating'] ?? 0.0).toDouble();

  int getTotalReviews(String boutiqueId) =>
      (_statsCache[boutiqueId]?['totalReviews'] ?? 0).toInt();

  Future<void> loadBoutiqueStats(String boutiqueId) async {
    if (boutiqueId.isEmpty || _loadingStats[boutiqueId] == true) return;

    _loadingStats[boutiqueId] = true;
    try {
      final stats = await _dataSource.fetchBoutiqueStats(boutiqueId);
      _statsCache[boutiqueId] = stats;
      update(); // Add this to notify GetBuilder widgets
    } catch (e) {
      error.value = 'Stats error: $e';
    } finally {
      _loadingStats.remove(boutiqueId);
      update(); // Ensure update happens even if there's an error
    }
  }

  void updateStats(String boutiqueId, Map<String, dynamic> stats) {
    if (boutiqueId.isNotEmpty) {
      _statsCache[boutiqueId] = stats;
      update(); // Make sure to call update() to notify listeners
    }
  }

  String? getOpticienNom(String? opticienId) {
    // Accepte maintenant String?
    if (opticienId == null) return null;

    try {
      final opticien = opticianController.opticians
          .firstWhereOrNull((o) => o.id == opticienId);
      return opticien != null ? '${opticien.nom} ${opticien.prenom}' : null;
    } catch (e) {
      return null;
    }
  }

  void _loadBoutiques() {
    final opticianController = Get.find<OpticianController>();
    if (opticianController.isLoggedIn.value) {
      // Charge seulement les boutiques de l'opticien connecté
      getboutiqueByOpticianId(opticianController.currentUserId.value);
    }
  }

  Future<void> refreshBoutiques() async {
    try {
      isLoading(true);
      error('');

      final opticianController = Get.find<OpticianController>();
      if (opticianController.isLoggedIn.value) {
        await getboutiqueByOpticianId(opticianController.currentUserId.value);
      } else {
        await getboutique();
      }
    } catch (e) {
      error(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> getboutique() async {
    try {
      final opticianController = Get.find<OpticianController>();

      // Si un opticien est connecté, ne charger que ses boutiques
      if (opticianController.isLoggedIn.value) {
        await getboutiqueByOpticianId(opticianController.currentUserId.value);
        return;
      }

      isLoading(true);
      error('');
      print('Fetching opticians...');

      final result = await boutiqueRepository.getOpticiens();
      opticiensList.assignAll(result);

      print('Fetched opticians: $result');
      print('Opticians list updated: $opticiensList');
    } catch (e) {
      error(e.toString());
      print('Error fetching opticians: $e');
    } finally {
      isLoading(false);
      print('Finished fetching opticians.');
    }
  }

  Future<void> getboutiqueByOpticianId(String opticienId) async {
    try {
      isLoading(true);
      error('');

      print('🔄 Chargement pour opticien: $opticienId');
      final result =
          await boutiqueRepository.getBoutiquesByOpticianId(opticienId);

      opticiensList.assignAll(result);
      print(
          '✅ Données reçues: ${result.length} | Stockées: ${opticiensList.length}');

      // Log de vérification
      if (opticiensList.isNotEmpty) {
        print(
            'Exemple: ${opticiensList.first.nom} - ${opticiensList.first.opticien_id}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      error(e.toString());
    } finally {
      isLoading(false);
    }
  }

  String? getOpticianName(String? opticianId) {
    if (opticianId == null) return null;
    final optician = opticianController.opticians
        .firstWhereOrNull((o) => o.id == opticianId);
    return optician?.nom ?? 'Non attribué'; // Retourne le nom ou "Non attribué"
  }

  Future<bool> addOpticien(Boutique opticien) async {
    try {
      isLoading(true);
      error('');

      print('Adding optician: ${opticien.toJson()}');

      if (opticien.nom.isEmpty ||
          opticien.adresse.isEmpty ||
          opticien.phone.isEmpty ||
          opticien.email.isEmpty ||
          opticien.description.isEmpty ||
          opticien.opening_hours.isEmpty) {
        throw Exception('All fields are required');
      }

      // If opticien_id is provided, try to fetch the optician name
      if (opticien.opticien_id != null) {
        try {
          final opticianDetails =
              await boutiqueRepository.getOpticienById(opticien.opticien_id!);
          // Only update if additional details are found
          if (opticianDetails != null && opticianDetails.nom.isNotEmpty) {
            opticien = Boutique(
                id: opticien.id,
                nom: opticien.nom,
                adresse: opticien.adresse,
                ville: opticien.ville,
                phone: opticien.phone,
                email: opticien.email,
                description: opticien.description,
                opening_hours: opticien.opening_hours,
                opticien_id: opticien.opticien_id,
                opticien_nom: opticianDetails.nom);
          }
        } catch (e) {
          print('Could not fetch optician details: $e');
        }
      }

      // Directly add the boutique with its details
      await boutiqueRepository.addOpticien(opticien);

      // Refresh the list to ensure the new boutique is loaded with all details
      await getboutique();

      return true;
    } catch (e) {
      error(e.toString());
      print('Error adding optician: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<Boutique?> getBoutiqueById(String id) async {
    try {
      isLoading(true);
      error('');
      final result = await boutiqueRepository.getOpticienById(id);
      selectedBoutique.value = result;
      return result;
    } catch (e) {
      error(e.toString());
      selectedBoutique.value = null;
      return null;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateOpticien(String id, Boutique opticien) async {
  try {
    isLoading(true);
    error('');

    await boutiqueRepository.updateOpticien(id, opticien);
    
    // Mise à jour directe de la liste sans recharger depuis le serveur
    final index = opticiensList.indexWhere((b) => b.id == id);
    if (index != -1) {
      opticiensList[index] = opticien;
    }

    return true;
  } catch (e) {
    error(e.toString());
    print('Error updating optician: $e');
    return false;
  } finally {
    isLoading(false);
  }
}

Future<bool> deleteOpticien(String id) async {
  try {
    isLoading(true);
    error('');

    await boutiqueRepository.deleteOpticien(id);
    
    // Suppression directe de la liste sans recharger depuis le serveur
    opticiensList.removeWhere((b) => b.id == id);

    return true;
  } catch (e) {
    error(e.toString());
    print('Error deleting optician: $e');
    return false;
  } finally {
    isLoading(false);
  }
}
}
