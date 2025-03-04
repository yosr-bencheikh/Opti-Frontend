import 'package:get/get.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/repositories/opticien_repository.dart';

class OpticienController extends GetxController {
  final OpticienRepository opticienRepository;
  final isLoading = false.obs;
  final opticiensList = <Opticien>[].obs;
  final error = RxString('');

  OpticienController({required this.opticienRepository});

  @override
  void onInit() {
    super.onInit();
    getOpticien();
  }

  Future<void> getOpticien() async {
    try {
      isLoading(true);
      error(''); // Reset error message
      print('Fetching opticians...'); // Log fetching start

      final result = await opticienRepository.getOpticiens();
      print('Fetched opticians: $result'); // Log fetched data

      // Directly assign the result if it's already a List<Opticien>
      opticiensList.assignAll(result);
      print('Opticians list updated: $opticiensList'); // Log updated list
    } catch (e) {
      error(e.toString());
      print('Error fetching opticians: $e'); // Log error
    } finally {
      isLoading(false);
      print('Finished fetching opticians.'); // Log fetching end
    }
  }
  
  // Add a new optician
Future<bool> addOpticien(Opticien opticien) async {
  try {
    isLoading(true);
    error('');

    // Debugging: Print the optician object
    print('Adding optician: ${opticien.toJson()}');

    // Ensure all required fields are provided
    if (opticien.nom.isEmpty ||
        opticien.adresse.isEmpty ||
        opticien.phone.isEmpty ||
        opticien.email.isEmpty ||
        opticien.description.isEmpty ||
        opticien.opening_hours.isEmpty) {
      throw Exception('All fields are required');
    }

    await opticienRepository.addOpticien(opticien);

    // Refresh the list after adding
    await getOpticien();

    return true;
  } catch (e) {
    error(e.toString());
    print('Error adding optician: $e');
    return false;
  } finally {
    isLoading(false);
  }
}
  // Update an existing optician
  Future<bool> updateOpticien(String id, Opticien opticien) async {
    try {
      isLoading(true);
      error('');
      
      
      await opticienRepository.updateOpticien(id, opticien);
      
      // Refresh the list after updating
      await getOpticien();
      
      return true;
    } catch (e) {
      error(e.toString());
      print('Error updating optician: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
  
  // Delete an optician
  Future<bool> deleteOpticien(String id) async {
    try {
      isLoading(true);
      error('');
      
      // Call the repository method to delete the optician
      // This needs to be implemented in the repository
      await opticienRepository.deleteOpticien(id);
      
      // Refresh the list after deleting
      await getOpticien();
      
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