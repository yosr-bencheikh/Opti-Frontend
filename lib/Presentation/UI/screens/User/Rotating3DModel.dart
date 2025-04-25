import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class Rotating3DModel extends StatefulWidget {
  final String modelUrl;

  const Rotating3DModel({Key? key, required this.modelUrl}) : super(key: key);

  @override
  _Rotating3DModelState createState() => _Rotating3DModelState();
}

class _Rotating3DModelState extends State<Rotating3DModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Créer un controller d'animation qui tourne en continu
    _controller = AnimationController(
      duration: const Duration(
          seconds: 10), // Une rotation complète prend 10 secondes
      vsync: this,
    )..repeat(); // Répéter l'animation indéfiniment
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159, // Rotation de 0 à 2π (360°)
          child: Flutter3DViewer(src: widget.modelUrl),
        );
      },
    );
  }
}
