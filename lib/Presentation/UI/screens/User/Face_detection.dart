import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:opti_app/Presentation/UI/screens/User/Recommendation.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  List<Face> _faces = [];
  String _faceShape = '';
  bool _isBusy = false;
  late Timer _timer;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _showRecommendationBubble =
      false; // Nouvelle variable pour contrôler l'affichage de la bulle

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
        _isCameraInitialized = true;
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
        String newFaceShape = _detectFaceShape(faces.first);

        // Si la forme du visage change ou est détectée pour la première fois
        if (newFaceShape != _faceShape &&
            newFaceShape != 'Indéterminé' &&
            newFaceShape != 'Aucun visage détecté' &&
            newFaceShape != 'Forme non reconnue') {
          _faceShape = newFaceShape;
          // Afficher la bulle de recommandation après 2 secondes
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showRecommendationBubble = true;
              });
            }
          });
        } else if (newFaceShape != 'Indéterminé' &&
            newFaceShape != 'Aucun visage détecté' &&
            newFaceShape != 'Forme non reconnue') {
          _faceShape = newFaceShape;
        }
      } else {
        _faceShape = 'Aucun visage détecté';
        _showRecommendationBubble = false;
      }
    });
  }

  String _detectFaceShape(Face face) {
    // Vérification du contour du visage
    final jawContour = face.contours[FaceContourType.face]?.points;
    if (jawContour == null || jawContour.length < 10) {
      print('Contour insuffisant: ${jawContour?.length ?? 0} points');
      return 'Indéterminé';
    }

    print('Nombre de points dans le contour: ${jawContour.length}');

    // Dimensions du visage
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final boundingBoxAspect = faceWidth / faceHeight;
    print('Dimensions: L=$faceWidth, H=$faceHeight, Ratio=$boundingBoxAspect');

    // Recherche des points extrêmes
    Point<double> leftmost =
        Point<double>(jawContour[0].x.toDouble(), jawContour[0].y.toDouble());
    Point<double> rightmost =
        Point<double>(jawContour[0].x.toDouble(), jawContour[0].y.toDouble());
    Point<double> lowest =
        Point<double>(jawContour[0].x.toDouble(), jawContour[0].y.toDouble());
    Point<double> highest =
        Point<double>(jawContour[0].x.toDouble(), jawContour[0].y.toDouble());

    for (var point in jawContour) {
      double x = point.x.toDouble();
      double y = point.y.toDouble();
      if (x < leftmost.x) leftmost = Point<double>(x, y);
      if (x > rightmost.x) rightmost = Point<double>(x, y);
      if (y > lowest.y) lowest = Point<double>(x, y);
      if (y < highest.y) highest = Point<double>(x, y);
    }
    print(
        'Points clés: Gauche=(${leftmost.x},${leftmost.y}), Droite=(${rightmost.x},${rightmost.y}), Bas=(${lowest.x},${lowest.y})');

    // Calcul des ratios
    final jawWidth = (rightmost.x - leftmost.x).abs();
    final jawHeight = (lowest.y - ((leftmost.y + rightmost.y) / 2)).abs();
    final cheekWidth = _findCheekWidth(jawContour);
    final widthRatio = jawWidth / faceWidth;
    final heightRatio = jawHeight / faceHeight;
    final cheekToJawRatio = cheekWidth / jawWidth;

    print(
        'Ratios: widthRatio=$widthRatio, heightRatio=$heightRatio, cheekToJawRatio=$cheekToJawRatio');

    // Ajustement des seuils pour une classification plus fine
    if (boundingBoxAspect > 1.2) {
      return 'Visage en Cœur';
    } else if (boundingBoxAspect < 0.75 && widthRatio > 0.8) {
      return 'Visage Rectangulaire';
    } else if (widthRatio > 0.85 &&
        heightRatio < 0.2 &&
        cheekToJawRatio < 1.0) {
      return 'Visage Carré';
    } else if (widthRatio > 0.8 && heightRatio > 0.3 && cheekToJawRatio > 1.2) {
      return 'Visage Rond';
    } else if (widthRatio > 0.85 &&
        heightRatio > 0.35 &&
        cheekToJawRatio < 1.0) {
      return 'Visage en Diamant';
    } else if (widthRatio < 0.7 &&
        heightRatio > 0.25 &&
        _isWidestAtCheeks(jawContour)) {
      return 'Visage Triangulaire';
    } else if (widthRatio < 0.7 && heightRatio < 0.2) {
      return 'Visage en forme de Poire';
    } else {
      // Par défaut, on considère le visage comme ovale
      return 'Visage Ovale';
    }
  }

  double _findCheekWidth(List<Point<num>> points) {
    // Détermination du min et max en Y pour définir la zone des pommettes
    double minY = points[0].y.toDouble();
    double maxY = points[0].y.toDouble();

    for (var point in points) {
      double y = point.y.toDouble();
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Position approximative des pommettes (1/3 depuis le haut)
    double cheekY = minY + (maxY - minY) / 3;
    double margin = (maxY - minY) * 0.05;

    double minX = double.infinity;
    double maxX = -double.infinity;

    // Recherche des points les plus à gauche et à droite autour de cheekY
    for (var point in points) {
      double x = point.x.toDouble();
      double y = point.y.toDouble();
      if (y >= cheekY - margin && y <= cheekY + margin) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }

    return (maxX - minX).abs();
  }

  bool _isWidestAtCheeks(List<Point<num>> points) {
    double cheekWidth = _findCheekWidth(points);

    // Recherche de la largeur maximale sur tout le contour
    double maxWidth = 0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        double width = (points[i].x.toDouble() - points[j].x.toDouble()).abs();
        if (width > maxWidth) maxWidth = width;
      }
    }
    // Vérifie si la largeur à la hauteur des pommettes est proche de la largeur maximale
    return cheekWidth > maxWidth * 0.9;
  }

// Fonction auxiliaire pour trouver le point le plus bas (menton)
  Point _findLowestPoint(List<Point> points) {
    Point lowest = points[0];
    for (var point in points) {
      if (point.y > lowest.y) {
        lowest = point;
      }
    }
    return lowest;
  }

  void _navigateToRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationScreen(faceShape: _faceShape),
      ),
    );
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
          // Affichage de la bulle de recommandation
          if (_showRecommendationBubble && _faceShape != 'Aucun visage détecté')
            Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: _navigateToRecommendations,
                child: Container(
                  width: 200,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recommandations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cliquez ici pour voir des conseils adaptés à votre $_faceShape',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.touch_app, color: Colors.blue),
                    ],
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
