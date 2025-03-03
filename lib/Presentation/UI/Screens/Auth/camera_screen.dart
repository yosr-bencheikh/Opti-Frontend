import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/FaacePainter.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate, // Optimized for accuracy
      enableContours: false, // Disable unnecessary features
      enableClassification: false, // Disable unnecessary features
    ),
  );
  List<Face> _faces = [];
  bool _isDetecting = false;
  bool _isSelfieMode = false; // Track if selfie mode is enabled
  List<CameraDescription>? _cameras; // List of available cameras
  int _selectedCameraIndex = 0; // Index of the currently selected camera

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    // Trouver la caméra avant/arrière
    _selectedCameraIndex = _isSelfieMode
        ? _cameras!
            .indexWhere((c) => c.lensDirection == CameraLensDirection.front)
        : _cameras!
            .indexWhere((c) => c.lensDirection == CameraLensDirection.back);

    if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

    _controller = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.medium, // Augmenter légèrement la résolution
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image, _controller!.description);
      if (inputImage == null) {
        debugPrint('Image ignorée - format non supporté');
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) setState(() => _faces = faces);
    } catch (e) {
      debugPrint("Erreur de détection: ${e.toString()}");
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(
      CameraImage image, CameraDescription description) {
    debugPrint('CameraImage format: ${image.format}'); // Log du format réel

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      debugPrint('Format non supporté: ${image.format}');
      return null;
    }

    // Gestion spécifique pour Android YUV
    if (Platform.isAndroid &&
        (format == InputImageFormat.yuv420 ||
            format == InputImageFormat.nv21)) {
      return _androidYuvConversion(image, description);
    }

    // Gestion iOS BGRA
    if (Platform.isIOS && format == InputImageFormat.bgra8888) {
      return _iOSBgraConversion(image, description);
    }

    debugPrint('Format non géré: $format');
    return null;
  }

  InputImage _androidYuvConversion(
      CameraImage image, CameraDescription description) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(
                description.sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21, // Forcer le format NV21 pour Android
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImage _iOSBgraConversion(
      CameraImage image, CameraDescription description) {
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(
                description.sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream(); // Stop the image stream
    _controller?.dispose(); // Dispose the camera controller
    _faceDetector.close(); // Close the face detector
    super.dispose();
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint('Aucune caméra disponible');
      return;
    }

    setState(() {
      _isSelfieMode = !_isSelfieMode; // Basculer entre selfie et mode normal
    });

    // Arrêter le flux d'images actuel
    await _controller?.stopImageStream();
    await _controller?.dispose();

    // Trouver l'index de la caméra avant ou arrière
    _selectedCameraIndex = _isSelfieMode
        ? _cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front)
        : _cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back);

    // Si aucune caméra avant n'est trouvée, utiliser la première caméra disponible
    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0;
    }

    // Réinitialiser le contrôleur de caméra avec la nouvelle caméra
    _controller = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset
          .medium, // Utiliser une résolution moyenne pour un bon équilibre
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420 // Format YUV pour Android
          : ImageFormatGroup.bgra8888, // Format BGRA pour iOS
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text("Détection des Yeux")),
      body: Stack(
        children: [
          // Apply horizontal flip for selfie mode
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(_isSelfieMode ? -1.0 : 1.0, 1.0),
            child: CameraPreview(_controller!),
          ),
          CustomPaint(
            painter: FacePainter(_faces),
            child: Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCamera, // Toggle between front and back camera
        child: Icon(_isSelfieMode ? Icons.camera_rear : Icons.camera_front),
      ),
    );
  }
}
