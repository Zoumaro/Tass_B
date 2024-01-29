// main.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = await availableCameras();
  CameraDescription firstCamera = cameras.first;

  runApp(MyApp(firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp(this.camera);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen(this.camera);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextDetector textDetector = GoogleMlKit.vision.textDetector();

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();

    textDetector.loadModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    textDetector.close();
    super.dispose();
  }

  Future<String> _detectText(XFile photo) async {
    final InputImage inputImage = InputImage.fromFilePath(photo.path);
    final RecognisedText recognisedText =
        await textDetector.processImage(inputImage);
    return recognisedText.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Example'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            XFile photo = await _controller.takePicture();
            String detectedText = await _detectText(photo);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  photo: photo,
                  detectedText: detectedText,
                ),
              ),
            );
          } catch (e) {
            print("Erreur lors de la prise de la photo : $e");
          }
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}

class CropImageScreen extends StatefulWidget {
  final XFile photo;

  CropImageScreen({required this.photo});

  @override
  _CropImageScreenState createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  Rect cropRect = Rect.fromPoints(Offset(0, 0), Offset(1, 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recadrer l\'image'),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            cropRect = cropRect.shift(details.delta);
          });
        },
        child: Center(
          child: ClipRect(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: Image.file(
                    File(widget.photo.path),
                    alignment: Alignment.topLeft,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      return child;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final textDetector = GoogleMlKitVision.textDetector(
  TextDetectorOptions(
    textModel: GoogleMlKitVisionTextModelOptions(
      confidenceThreshold: 0.8,
      language: 'en',
    ),
  ),
);

class DisplayPictureScreen extends StatelessWidget {
  final XFile photo;
  final String detectedText;

  const DisplayPictureScreen({required this.photo, required this.detectedText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Preview'),
      ),
      body: Stack(
        children: [
          Image.file(
            File(photo.path),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
          ),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(16.0),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              detectedText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
