// ignore: avoid_web_libraries_in_flutter
import 'dart:html'; // Pour IFrameElement
import 'dart:ui_web' as ui_web;  // Remplace l'ancien import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html'; // Pour IFrameElement

// conditionnel : dart:ui_web uniquement sur le web
// ignore: uri_does_not_exist
import 'dart:ui_web' as ui_web;

class Model3DViewer extends StatefulWidget {
  final String modelUrl;

  const Model3DViewer({Key? key, required this.modelUrl}) : super(key: key);

  @override
  State<Model3DViewer> createState() => _Model3DViewerState();
}

class _Model3DViewerState extends State<Model3DViewer> {
  @override
  void initState() {
    super.initState();
    _registerView();
  }

  void _registerView() {
    // Utilisation correcte de l'API actuelle
    ui_web.platformViewRegistry.registerViewFactory(
      'model-viewer-${widget.modelUrl.hashCode}',
      (int viewId) => IFrameElement()
        ..srcdoc = '''
<!DOCTYPE html>
<html>
<head>
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    body { margin: 0; padding: 0; }
    model-viewer { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <model-viewer
    src="${widget.modelUrl}"
    camera-controls
    auto-rotate
    ar
    background-color="#FFFFFF">
  </model-viewer>
</body>
</html>
        '''
        ..style.border = 'none',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
   width: MediaQuery.of(context).size.width * 0.9,
  height: MediaQuery.of(context).size.height * 0.8,
  child: HtmlElementView(
    viewType: 'model-viewer-${widget.modelUrl.hashCode}',
  ),
    );
  }
}