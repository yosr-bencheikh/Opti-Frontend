import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
    String route;
    switch (index) {
      case 0:
        route = '/HomeScreen';
        break;
      case 1:
        route = '/stores';
        break;
      case 2:
        route = '/orderList';
        break;
      case 3:
        route = '/profileScreen';
        break;
      default:
        route = '/HomeScreen';
    }
    Get.offAllNamed(route); // Replaces current route
  }
 

  // New method to set index without animation
  void setSelectedIndex(int index) {
    selectedIndex.value = index;
  }
}
