import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class MultiColorPickerTile extends StatefulWidget {
  final Product product;
  final Function(List<String>) onColorsChanged;

  const MultiColorPickerTile({
    Key? key,
    required this.product,
    required this.onColorsChanged,
  }) : super(key: key);

  @override
  State<MultiColorPickerTile> createState() => _MultiColorPickerTileState();
}

class _MultiColorPickerTileState extends State<MultiColorPickerTile> {
  List<Color> selectedColors = [];

  @override
  void initState() {
    super.initState();
    // Convert hex colors to Color objects
    selectedColors =
        widget.product.couleur.map((hex) => getColorFromHex(hex)).toList();

    // Ensure there's at least one color in the list
    if (selectedColors.isEmpty) {
      selectedColors.add(Colors.grey);
    }
  }

  Color getColorFromHex(String hexString) {
    // Add # if not present
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 8) {
      buffer.write('ff');
      buffer.write(hexString);
      return Color(int.parse(buffer.toString(), radix: 16));
    }
    return Colors.grey; // Default fallback color
  }

  String colorToHex(Color color) {
    return color.red.toRadixString(16).padLeft(2, '0') +
        color.green.toRadixString(16).padLeft(2, '0') +
        color.blue.toRadixString(16).padLeft(2, '0');
  }

  void _addNewColor() {
    setState(() {
      selectedColors.add(Colors.grey);

      // Update product's color list
      List<String> hexColors =
          selectedColors.map((c) => colorToHex(c)).toList();
      widget.product.couleur = hexColors;
      widget.onColorsChanged(hexColors);
    });
  }

  void _removeColor(int index) {
    if (selectedColors.length > 1) {
      setState(() {
        selectedColors.removeAt(index);

        // Update product's color list
        List<String> hexColors =
            selectedColors.map((c) => colorToHex(c)).toList();
        widget.product.couleur = hexColors;
        widget.onColorsChanged(hexColors);
      });
    }
  }

  Future<void> _pickColor(int index) async {
    Color initialColor = selectedColors[index];

    final Color? pickedColor = await showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = initialColor;
        return AlertDialog(
          title: const Text('Sélectionnez une couleur'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, tempColor);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        selectedColors[index] = pickedColor;

        // Update product's color list
        List<String> hexColors =
            selectedColors.map((c) => colorToHex(c)).toList();
        widget.product.couleur = hexColors;
        widget.onColorsChanged(hexColors);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Couleurs'),
            subtitle: const Text('Sélectionnez plusieurs couleurs'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Color chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    selectedColors.length,
                    (index) => InkWell(
                      onTap: () => _pickColor(index),
                      child: Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedColors[index],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => _removeColor(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Icon(Icons.close, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Add color button
                ElevatedButton.icon(
                  onPressed: _addNewColor,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une couleur'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
