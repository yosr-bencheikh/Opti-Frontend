import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class Fixed3DViewer extends StatefulWidget {
  final String modelUrl;
  final bool compactMode;
  final bool autoRotate;
  final int autoRotateDelay;
  final double autoRotateSpeed;
  
  const Fixed3DViewer({
    Key? key,
    required this.modelUrl,
    this.compactMode = false,
    this.autoRotate = false,
    this.autoRotateDelay = 0,
    this.autoRotateSpeed = 1.0,
  }) : super(key: key);

  @override
  State<Fixed3DViewer> createState() => _Fixed3DViewerState();
}

class _Fixed3DViewerState extends State<Fixed3DViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  String _localModelPath = "";
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _prepareModel();
  }

  Future<void> _prepareModel() async {
    if (widget.modelUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = "URL du modèle vide";
      });
      return;
    }

    try {
      // Si nous sommes sur Android et que l'URL est distante, téléchargeons-la
      if (!kIsWeb && Platform.isAndroid && widget.modelUrl.startsWith('http')) {
        await _downloadModel();
      } else {
        setState(() {
          _isLoading = false;
          _localModelPath = widget.modelUrl;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = "Erreur: $e";
      });
      print("Erreur lors de la préparation du modèle: $e");
    }
  }

  Future<void> _downloadModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = widget.modelUrl.split('/').last;
      final savePath = '${appDir.path}/$fileName';
      final file = File(savePath);
      
      // Vérifier si le fichier existe déjà en cache
      if (await file.exists()) {
        print("Utilisation du modèle en cache: $savePath");
        setState(() {
          _localModelPath = savePath;
          _isLoading = false;
        });
        return;
      }
      
      // Télécharger le fichier
      print("Téléchargement du modèle: ${widget.modelUrl}");
      await _dio.download(
        widget.modelUrl, 
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print("Téléchargement: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        }
      );
      
      print("Modèle téléchargé avec succès: $savePath");
      
      if (mounted) {
        setState(() {
          _localModelPath = savePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = "Erreur de téléchargement: $e";
        });
      }
      print("Erreur lors du téléchargement du modèle: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modelUrl.isEmpty) {
      return Center(
        child: Icon(Icons.do_not_disturb_on, size: 24, color: Colors.grey[400]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          if (!_isLoading && !_hasError && _localModelPath.isNotEmpty)
            SizedBox(
              width: 160,
              height: 120,
              child: Flutter3DViewer(
                src: _localModelPath,
            
                onError: (error) {
                  print("Erreur du viewer 3D: $error");
                  if (mounted) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = error;
                    });
                  }
                },
onLoad: (String message) {
  print("Modèle 3D chargé avec succès: $_localModelPath");
},


              ),
            ),
          
          // Afficher un loader pendant le chargement
          if (_isLoading)
            Container(
              width: 160,
              height: 120,
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Afficher une erreur en cas de problème
          if (_hasError)
            Container(
              width: 160,
              height: 120,
              color: Colors.black12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[300], size: 30),
                  const SizedBox(height: 4),
                  Text(
                    "Erreur modèle 3D",
                    style: TextStyle(fontSize: 10, color: Colors.red[300]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}