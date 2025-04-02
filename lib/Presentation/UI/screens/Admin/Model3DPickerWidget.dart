import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class Model3DPickerWidget extends StatefulWidget {
  final Function(PlatformFile) onFilePicked;

  const Model3DPickerWidget({Key? key, required this.onFilePicked}) : super(key: key);

  @override
  _Model3DPickerWidgetState createState() => _Model3DPickerWidgetState();
}

class _Model3DPickerWidgetState extends State<Model3DPickerWidget> {
  PlatformFile? _selectedFile;

  Future<void> _pickModel3D() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf'],
        withData: true, // Nécessaire pour le web
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
        widget.onFilePicked(_selectedFile!);
      }
    } catch (e) {
      print('Erreur lors de la sélection du fichier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _pickModel3D,
          icon: const Icon(Icons.view_in_ar),
          label: const Text('Sélectionner un modèle 3D (.glb, .gltf)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (_selectedFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Fichier sélectionné: ${_selectedFile!.name}',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
      ],
    );
  }
}