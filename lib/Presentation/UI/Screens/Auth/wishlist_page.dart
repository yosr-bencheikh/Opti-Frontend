import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';

class WishlistPage extends StatelessWidget {
  final String userEmail;

  const WishlistPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.find<WishlistController>();

    // Initialize with user email instead of userId
    controller.initUser(userEmail);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

      if (controller.wishlistItems.isEmpty) {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Your wishlist is empty'),
      ],
    ),
  );
}

        return ListView.builder(
          itemCount: controller.wishlistItems.length,
          itemBuilder: (context, index) {
            final item = controller.wishlistItems[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
  leading: item.product.imageUrl != null
      ? Image.network(
          item.product.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        )
      : const Icon(Icons.image_not_supported),
  title: Text(item.product.name),
  subtitle: Text('${item.product.prix} DT'),
  trailing: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () => controller.removeFromWishlist(item.id),
  ),
)
            );
          },
        );
      }),
    );
  }
}
