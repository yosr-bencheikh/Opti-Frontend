// Presentation/controllers/OpticianController.dart
import 'package:get/get.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/domain/entities/Optician.dart';

class OpticianController extends GetxController {
  final OpticianDataSource _dataSource = OpticianDataSourceImpl();
  var opticians = <Optician>[].obs; // Observable list of opticians
  var isLoading = true.obs; // Loading state
  var error = ''.obs; // Error message

  @override
  void onInit() {
    fetchOpticians(); // Fetch opticians when the controller is initialized
    super.onInit();
  }

  // Fetch all opticians
  Future<void> fetchOpticians() async {
    try {
      isLoading(true); // Set loading to true
      error(''); // Clear any previous errors
      final result = await _dataSource.getOpticians(); // Fetch data
      opticians.assignAll(result); // Update the observable list
    } catch (e) {
      error(e.toString()); // Set error message
      Get.snackbar('Error', 'Failed to fetch opticians: ${e.toString()}');
    } finally {
      isLoading(false); // Set loading to false
    }
  }

  // Add a new optician
  Future<void> addOptician(Optician optician) async {
    try {
      isLoading(true);
      error('');
      await _dataSource.addOptician(optician); // Add optician to the data source
      Get.snackbar('Success', 'Optician added successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to add optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Update an existing optician
  Future<void> updateOptician(Optician optician) async {
    try {
      isLoading(true);
      error('');
      await _dataSource.updateOptician(optician); // Update optician in the data source
      Get.snackbar('Success', 'Optician updated successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to update optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Delete an optician
  Future<void> deleteOptician(String id) async {
    try {
      isLoading(true);
      error('');
      await _dataSource.deleteOptician(id); // Delete optician from the data source
      Get.snackbar('Success', 'Optician deleted successfully');
      await fetchOpticians(); // Refresh the list
    } catch (e) {
      error(e.toString());
      Get.snackbar('Error', 'Failed to delete optician: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }
}