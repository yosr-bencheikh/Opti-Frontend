// lib/presentation/widgets/product_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class ProductDialog extends StatefulWidget {
  final Product product;

  const ProductDialog({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  int quantity = 1;
  final CartItemController cartController = Get.find();
  final AuthController authController = Get.find();

  void _addToCart() {
    final userId = authController.currentUserId.value;
    final totalPrice = quantity * widget.product.prix;

    if (userId.isNotEmpty && widget.product.id != null) {
      cartController.createCartItem(
        userId: userId,
        productId: widget.product.id!,
        quantity: quantity,
        totalPrice: totalPrice,
      );
      Get.back();
      Get.snackbar(
        'Success',
        'Item added to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Unable to add item to cart. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = quantity * widget.product.prix;

    return AlertDialog(
      title: Text(widget.product.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.product.imageUrl ?? '',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: \$${widget.product.prix.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total: \$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addToCart,
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
