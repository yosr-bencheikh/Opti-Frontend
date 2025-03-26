import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/data/repositories/boutique_repository_impl.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';

class BoutiqueController extends GetxController {
  final BoutiqueRepository boutiqueRepository;
  final OpticianController opticianController;
  final isLoading = false.obs;
  final opticiensList = <Boutique>[].obs;
  final error = RxString('');
  final selectedBoutique = Rx<Boutique?>(null);
  final RxList<Optician> _opticiens = <Optician>[].obs;
  final RxBool _showOnlyUserBoutiques = false.obs;

  BoutiqueController(this.opticianController, {required this.boutiqueRepository});

 @override
  void onInit() {
    super.onInit();
    final opticianController = Get.find<OpticianController>();
    
    // Définir si on montre seulement les boutiques de l'utilisateur
    _showOnlyUserBoutiques.value = opticianController.isLoggedIn.value;
    
    // Charger les boutiques appropriées
    if (_showOnlyUserBoutiques.value) {
      getboutiqueByOpticianId(opticianController.currentUserId.value);
    } else {
      getboutique();
    }
  }
    Future<void> refreshBoutiques() async {
    final opticianController = Get.find<OpticianController>();
    if (_showOnlyUserBoutiques.value) {
      await getboutiqueByOpticianId(opticianController.currentUserId.value);
    } else {
      await getboutique();
    }
  }
String? getOpticienNom(String? opticienId) {  // Accepte maintenant String?
  if (opticienId == null) return null;
  
  try {
    final opticien = opticianController.opticians.firstWhereOrNull(
      (o) => o.id == opticienId
    );
    return opticien != null ? '${opticien.nom} ${opticien.prenom}' : null;
  } catch (e) {
    return null;
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

      opticiensList.assignAll(result);
      print('Opticians list updated: $opticiensList');
    } catch (e) {
      error(e.toString());
      print('Error fetching opticians: $e');
    } finally {
      isLoading(false);
      print('Finished fetching opticians.');
    }
  }

  Future<void> getboutiqueByOpticianId(String opticianId) async {
    try {
      isLoading(true);
      opticiensList.clear();
      error('');
      print('Fetching boutiques for optician: $opticianId');

      final result = await boutiqueRepository.getBoutiquesByOpticianId(opticianId);
      
      // Efface la liste existante avant d'ajouter les nouvelles boutiques
      opticiensList.clear();
      opticiensList.addAll(result);
      
      print('Boutiques mises à jour: ${opticiensList.length}');
    } catch (e) {
      error(e.toString());
      print('Error fetching boutiques: $e');
    } finally {
      isLoading(false);
    }
  }
String? getOpticianName(String? opticianId) {
  if (opticianId == null) return null;
  final optician = opticianController.opticians.firstWhereOrNull((o) => o.id == opticianId);
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
      await getboutique();

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
      await getboutique();

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
