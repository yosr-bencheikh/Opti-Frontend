import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class Fixed3DViewer extends StatefulWidget {
  final String modelUrl;
  final bool compactMode;
  final Color backgroundColor;
  final bool enableShadow;
  final double? exposure;
  final String? environmentImage;
  final bool autoRotate;
  final int rotationSpeed;
  final bool enableZoom;
  final String minCameraOrbit;  // Changed to String
  final String maxCameraOrbit;  // Changed to String
  final bool showProgress;
  final Color progressBarColor;
  
  const Fixed3DViewer({
    Key? key, 
    required this.modelUrl,
    this.compactMode = false,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.enableShadow = true,
    this.exposure,
    this.environmentImage,
    this.autoRotate = true,
    this.rotationSpeed = 30,
    this.enableZoom = true,
    this.minCameraOrbit = '0deg 60deg auto',  // Default as String
    this.maxCameraOrbit = '360deg 60deg auto', // Default as String
    this.showProgress = true,
    this.progressBarColor = Colors.blue,
  }) : super(key: key);
  
  @override
  State<Fixed3DViewer> createState() => _Fixed3DViewerState();
}

class _Fixed3DViewerState extends State<Fixed3DViewer> {
  late final String _viewType;
  bool _isLoading = true;
  bool _hasError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = '3d-viewer-${DateTime.now().millisecondsSinceEpoch}';
    _initializeView();
  }

  @override
  void didUpdateWidget(Fixed3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelUrl != widget.modelUrl) {
      _isLoading = true;
      _hasError = false;
      _error = null;
      _initializeView();
    }
  }

  void _initializeView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..srcdoc = _buildHtmlContent()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block';

        html.window.onMessage.listen((event) {
          final data = event.data;
          if (data is String) {
            if (data == 'model-loaded') {
              setState(() {
                _isLoading = false;
              });
            } else if (data.startsWith('error:')) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _error = data.substring(6);
              });
            }
          }
        });

        return iframe;
      },
    );
  }

  String _buildHtmlContent() {
    final bgColor = '#${widget.backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final progressColor = '#${widget.progressBarColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    
    final controlsHtml = widget.compactMode ? '' : '''
      <div class="controls-container">
        <button id="reset-button" class="control-button" title="Réinitialiser la caméra">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 12a9 9 0 1 0 18 0 9 9 0 0 0-18 0z"></path>
            <path d="M12 8v4l3 3"></path>
          </svg>
        </button>
        <button id="rotate-button" class="control-button" title="Activer/désactiver la rotation">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"></path>
            <path d="M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0z"></path>
            <path d="M12 16v4"></path>
            <path d="M12 4v4"></path>
          </svg>
        </button>
      </div>
    ''';
    
    final controlsScript = widget.compactMode ? '' : '''
      // Gestion des boutons de contrôle
      const resetButton = document.getElementById('reset-button');
      const rotateButton = document.getElementById('rotate-button');
      
      resetButton.addEventListener('click', () => {
        modelViewer.cameraOrbit = 'auto auto auto';
        modelViewer.cameraTarget = 'auto auto auto';
        modelViewer.fieldOfView = 'auto';
      });
      
      rotateButton.addEventListener('click', () => {
        modelViewer.autoRotate = !modelViewer.autoRotate;
      });
    ''';
    
    return '''
      <!DOCTYPE html>
      <html style="height: 100%; margin: 0;">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
        <style>
          body, html { 
            margin: 0; 
            padding: 0; 
            width: 100%; 
            height: 100%; 
            overflow: hidden;
            font-family: sans-serif;
          }
          model-viewer {
            width: 100%;
            height: 100%;
            background-color: ${bgColor};
            --progress-bar-color: ${widget.showProgress ? progressColor : 'transparent'};
            --progress-bar-height: 4px;
            --progress-mask: linear-gradient(to right, transparent 0%, rgba(0, 0, 0, 0.4) 50%, transparent 100%);
          }
          .error-message {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(255, 0, 0, 0.1);
            padding: 16px;
            border-radius: 8px;
            text-align: center;
            max-width: 80%;
            color: #d32f2f;
          }
          .loading-spinner {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 40px;
            height: 40px;
            border: 4px solid rgba(0, 0, 0, 0.1);
            border-radius: 50%;
            border-top-color: ${progressColor};
            animation: spin 1s ease-in-out infinite;
          }
          @keyframes spin {
            to { transform: translate(-50%, -50%) rotate(360deg); }
          }
          .controls-container {
            position: absolute;
            bottom: 16px;
            left: 16px;
            display: flex;
            gap: 8px;
            opacity: 0.8;
          }
          .control-button {
            background: rgba(255, 255, 255, 0.6);
            border: none;
            border-radius: 50%;
            width: 36px;
            height: 36px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            transition: background 0.2s;
          }
          .control-button:hover {
            background: rgba(255, 255, 255, 0.9);
          }
          .control-button svg {
            width: 20px;
            height: 20px;
          }
        </style>
      </head>
      <body style="height: 100%; margin: 0;">
        <div id="model-container" style="width: 100%; height: 100%; position: relative;">
          <model-viewer
            id="model"
            src="${widget.modelUrl}"
            ${widget.compactMode ? 'interaction-prompt="none"' : 'interaction-prompt="auto"'}
            camera-controls="${widget.compactMode ? 'false' : 'true'}"
            auto-rotate="${widget.autoRotate ? 'true' : 'false'}"
            rotation-per-second="${widget.rotationSpeed}deg"
            ${widget.enableShadow ? 'shadow-intensity="1"' : 'shadow-intensity="0"'}
            ${widget.exposure != null ? 'exposure="${widget.exposure}"' : ''}
            ${widget.environmentImage != null ? 'environment-image="${widget.environmentImage}"' : ''}
            min-camera-orbit="${widget.minCameraOrbit}deg auto auto"
            max-camera-orbit="${widget.maxCameraOrbit}deg auto auto"
            ${widget.enableZoom ? '' : 'disable-zoom'}
            style="width: 100%; height: 100%;"
            alt="Modèle 3D"
          ></model-viewer>

          <div id="loading" class="loading-spinner"></div>
          <div id="error-container" style="display: none;" class="error-message">
            <p id="error-message">Impossible de charger le modèle 3D</p>
          </div>

          ${controlsHtml}
        </div>

        <script>
          const modelViewer = document.getElementById('model');
          const loading = document.getElementById('loading');
          const errorContainer = document.getElementById('error-container');
          const errorMessage = document.getElementById('error-message');
          
          modelViewer.addEventListener('load', () => {
            loading.style.display = 'none';
            window.parent.postMessage('model-loaded', '*');
          });

          modelViewer.addEventListener('error', (error) => {
            loading.style.display = 'none';
            errorContainer.style.display = 'block';
            errorMessage.textContent = 'Erreur lors du chargement du modèle 3D: ' + error.detail.sourceError;
            window.parent.postMessage('error:' + error.detail.sourceError, '*');
          });

          ${controlsScript}
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: HtmlElementView(
            viewType: _viewType,
          ),
        ),
        if (_isLoading && widget.showProgress)
          Center(
            child: CircularProgressIndicator(
              color: widget.progressBarColor,
            ),
          ),
        if (_hasError)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error ?? 'Failed to load 3D model',
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ),
      ],
    );
  }
}