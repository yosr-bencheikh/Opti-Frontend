import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Glasses3DPage extends StatelessWidget {
  final String modelPath;

  const Glasses3DPage({Key? key, this.modelPath = 'assets/models/scene.gltf'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("3D Glasses View")),
      body: Center(
        child: ModelViewer(
          src: modelPath,
          ar: true,
          autoRotate: true,
          cameraControls: true,
        ),
      ),
    );
  }
}