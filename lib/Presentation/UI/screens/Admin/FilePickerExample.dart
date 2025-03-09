import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerExample extends StatefulWidget {
  final Function(PlatformFile?) onImagePicked;
  final String? initialImageUrl;

  const FilePickerExample({Key? key, required this.onImagePicked, this.initialImageUrl}) : super(key: key);

  @override
  _FilePickerExampleState createState() => _FilePickerExampleState();
}

class _FilePickerExampleState extends State<FilePickerExample> {
  PlatformFile? _selectedImage;

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = result.files.first;
          widget.onImagePicked(_selectedImage);
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: kIsWeb
                    ? Image.memory(
                        _selectedImage!.bytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_selectedImage!.path!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
              )
            : widget.initialImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      widget.initialImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey[600],
                  ),
      ),
    );
  }
}