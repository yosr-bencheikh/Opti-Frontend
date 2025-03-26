import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController; // Use nullable instead of late
  late FaceDetector _faceDetector;
  List<Face> _faces = [];
  String _faceShape = '';
  bool _isBusy = false;
  late Timer _timer;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false; // Track camera initialization state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      // Find the front-facing camera
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex =
            0; // Use the first camera if no front camera is found
      }
      await _startCamera(_selectedCameraIndex);
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    _cameraController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true; // Mark camera as initialized
      });
      _startImageStream();
    } catch (e) {
      print("Error starting camera: $e");
    }
  }

  void _startImageStream() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_isBusy || !_isCameraInitialized) return;
      _isBusy = true;

      try {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);

        final faces = await _faceDetector.processImage(inputImage);
        _updateFaceData(faces);

        await File(image.path).delete();
      } catch (e) {
        print("Error processing image: $e");
      } finally {
        _isBusy = false;
      }
    });
  }

  void _updateFaceData(List<Face> faces) {
    if (!mounted) return;

    setState(() {
      _faces = faces;
      if (faces.isNotEmpty) {
        _faceShape = _detectFaceShape(faces.first);
      } else {
        _faceShape = 'Aucun visage détecté';
      }
    });
  }

  String _detectFaceShape(Face face) {
    // Récupération du contour du visage (ici, on utilise le contour global "face")
    final jawContour = face.contours[FaceContourType.face]?.points;
    if (jawContour == null || jawContour.length < 10) return 'Indéterminé';

    // Dimensions du visage à partir du bounding box
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final boundingBoxAspect = faceWidth / faceHeight;

    // Définition de points clés sur le contour
    final leftJaw = jawContour.first; // Premier point (extrémité gauche)
    final rightJaw = jawContour[
        jawContour.length ~/ 2]; // Point central approximatif (droite)
    final chin = jawContour.last; // Dernier point (menton)

    // Calcul de la largeur de la mâchoire et d'une "hauteur" de la mâchoire
    final jawWidth = rightJaw.x - leftJaw.x;
    final jawHeight = chin.y - ((leftJaw.y + rightJaw.y) / 2);

    // Calcul des ratios (par rapport aux dimensions globales du visage)
    final widthRatio = jawWidth / faceWidth;
    final heightRatio = jawHeight / faceHeight;

    if (widthRatio > 0.85 && heightRatio < 0.25) {
      return 'Visage Carré';
    } else if (widthRatio > 0.75 && heightRatio > 0.3) {
      return 'Visage Rond';
    } else if (widthRatio < 0.7 && heightRatio < 0.25) {
      return 'Visage Ovale';
    } else if (boundingBoxAspect < 0.75) {
      return 'Visage Rectangulaire';
    } else if (boundingBoxAspect > 1.1) {
      return 'Visage en Cœur';
    } else if (widthRatio > 0.9 && heightRatio > 0.35) {
      return 'Visage en Diamant';
    } else if (widthRatio < 0.65 && heightRatio > 0.3) {
      return 'Visage Triangulaire';
    } else if (widthRatio < 0.65 && heightRatio < 0.2) {
      return 'Visage en forme de Poire';
    }

    return 'Forme non reconnue';
  }

  void _switchCamera() {
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _startCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse de Visage en Temps Réel'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(
            painter: FacePainter(_faces, _cameraController!),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Text(
                'Forme détectée: $_faceShape',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final CameraController cameraController;

  FacePainter(this.faces, this.cameraController);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final face in faces) {
      final box = _scaleRect(face.boundingBox, size);
      canvas.drawRect(box, paint);

      face.contours.forEach((type, contour) {
        if (contour != null) {
          contour.points.forEach((point) {
            final adjustedPoint = _scalePoint(point, size);
            canvas.drawCircle(adjustedPoint, 2, paint);
          });
        }
      });
    }
  }

  Rect _scaleRect(Rect rect, Size size) {
    final scaleX = size.width / cameraController.value.previewSize!.height;
    final scaleY = size.height / cameraController.value.previewSize!.width;
    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  Offset _scalePoint(Point point, Size size) {
    final scaleX = size.width / cameraController.value.previewSize!.height;
    final scaleY = size.height / cameraController.value.previewSize!.width;
    return Offset(point.x * scaleX, point.y * scaleY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
