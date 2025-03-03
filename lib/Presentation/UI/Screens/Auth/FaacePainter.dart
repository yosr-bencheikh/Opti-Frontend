import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (Face face in faces) {
      canvas.drawRect(face.boundingBox, paint);

      // Access landmarks via the map
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;

      if (leftEye != null) {
        canvas.drawCircle(Offset(leftEye.x as double, leftEye.y as double), 5, paint);
      }
      if (rightEye != null) {
        canvas.drawCircle(Offset(rightEye.x as double, rightEye.y as double), 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}