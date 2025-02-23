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
}
