import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'preview_screen.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = kIsWeb ? <CameraDescription>[] : await availableCameras();

  runApp(
    MaterialApp(
      theme: ThemeData.light(),
      home: cameras.isEmpty
          ? const NoCamerasScreen()
          : MyHomePage(cameras: cameras),
    ),
  );
}

class NoCamerasScreen extends StatelessWidget {
  const NoCamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Myflutter App')),
      body: const Center(
        child: Text('No cameras found on this device.'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Myflutter App')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!kIsWeb)
              ElevatedButton(
                style: buttonStyle,
                child: const Text('Take a Picture'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TakePictureScreen(camera: cameras.first),
                    ),
                  );
                },
              ),
            if (!kIsWeb) ...[
              const SizedBox(width: 16),
              ElevatedButton(
                style: buttonStyle,
                child: const Text('Record Audio'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordAudioScreen(),
                    ),
                  );
                },
              ),
            ],
            if (kIsWeb)
              const Text('Camera and audio recording are not available on the web.'),
          ],
        ),
      ),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and then get the location
            // where the image file is saved.
            final image = await _controller.takePicture();

            if (!mounted) return;

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PreviewScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class RecordAudioScreen extends StatefulWidget {
  const RecordAudioScreen({super.key});

  @override
  _RecordAudioScreenState createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final PlayerController _playerController;
  bool _isRecording = false;
  String? _selectedFilePath;
  late Future<List<FileSystemEntity>> _recordedFiles;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _recordedFiles = _getRecordedFiles();
    }
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<List<FileSystemEntity>> _getRecordedFiles() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final myFlutterPath = p.join(appDocumentsDir.path, 'myflutter');
    final directory = Directory(myFlutterPath);
    if (await directory.exists()) {
      return directory
          .listSync()
          .where((item) => item.path.endsWith('.opus'))
          .toList();
    }
    return [];
  }

  void _refreshRecordedFiles() {
    setState(() {
      _recordedFiles = _getRecordedFiles();
    });
  }

  Future<void> _deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _refreshRecordedFiles();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final myFlutterPath = p.join(appDocumentsDir.path, 'myflutter');
      await Directory(myFlutterPath).create(recursive: true);
      final filePath = p.join(
          myFlutterPath, 'audio_${DateTime.now().millisecondsSinceEpoch}.opus');

      await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: filePath);
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });
    _refreshRecordedFiles();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio'),
      ),
      body: kIsWeb
          ? const Center(
              child: Text('Audio recording is not available on the web.'),
            )
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed:
                            _isRecording ? _stopRecording : _startRecording,
                        child: Text(
                            _isRecording ? 'Stop Recording' : 'Start Recording'),
                      ),
                    ],
                  ),
                ),
                if (_selectedFilePath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AudioFileWaveforms(
                      size: Size(MediaQuery.of(context).size.width * 0.8, 100.0),
                      playerController: _playerController,
                      enableSeekGesture: true,
                      waveformType: WaveformType.long,
                      playerWaveStyle: const PlayerWaveStyle(
                        fixedWaveColor: Colors.white,
                        liveWaveColor: Colors.blueAccent,
                        spacing: 6,
                      ),
                    ),
                  ),
                const Text('Recorded Files',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: FutureBuilder<List<FileSystemEntity>>(
                    future: _recordedFiles,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No recordings found.'));
                      } else {
                        final files = snapshot.data!;
                        return ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return ListTile(
                              title: Text(p.basename(file.path)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () {
                                      _playerController
                                          .preparePlayer(
                                            path: file.path,
                                            shouldExtractWaveform: true,
                                          )
                                          .then((_) =>
                                              _playerController.startPlayer());

                                      setState(() {
                                        _selectedFilePath = file.path;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop),
                                    onPressed: () {
                                      _playerController.stopPlayer();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _deleteRecording(file.path),
                                  ),
                                ],
                              ),
                              selected: _selectedFilePath == file.path,
                              selectedTileColor: Colors.blue.withOpacity(0.3),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
