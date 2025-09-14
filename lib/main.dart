import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<File>> _imageFiles;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _imageFiles = _getSavedImages();
    }
  }

  Future<List<File>> _getSavedImages() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final picturesPath = p.join(appDocumentsDir.path, 'pictures');
    final directory = Directory(picturesPath);
    if (await directory.exists()) {
      return directory
          .listSync()
          .where((item) => item.path.endsWith('.jpg'))
          .map((item) => File(item.path))
          .toList();
    }
    return [];
  }

  void _refreshImages() {
    setState(() {
      _imageFiles = _getSavedImages();
    });
  }

  Future<void> _deleteImage(File imageFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      _refreshImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Myflutter App')),
      body: Column(
        children: [
          if (!kIsWeb)
            Expanded(
              child: FutureBuilder<List<File>>(
                future: _imageFiles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No images found.'));
                  } else {
                    final images = snapshot.data!;
                    return ListView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imageFile = images[index];
                        return ListTile(
                          leading: Image.file(
                            imageFile,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(p.basename(imageFile.path)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PreviewScreen(imagePath: imageFile.path, isTemporary: false),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteImage(imageFile),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!kIsWeb)
                ElevatedButton(
                  style: buttonStyle,
                  child: const Text('Take a Picture'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TakePictureScreen(camera: widget.cameras.first),
                      ),
                    );
                    _refreshImages();
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
                const Text(
                    'Camera and audio recording are not available on the web.'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

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
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!mounted) return;
            await navigator.push(
              MaterialPageRoute(
                builder: (context) => PreviewScreen(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            debugPrint('Error taking picture: $e');
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
  RecordAudioScreenState createState() => RecordAudioScreenState();
}

class RecordAudioScreenState extends State<RecordAudioScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final aw.PlayerController _playerController = aw.PlayerController();
  final AudioPlayer _durationPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _selectedFilePath;
  late Future<List<Map<String, dynamic>>> _recordedFiles;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _recordedFiles = _getRecordedFiles();
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _playerController.dispose();
    _durationPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getRecordedFiles() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final myFlutterPath = p.join(appDocumentsDir.path, 'myflutter');
    final directory = Directory(myFlutterPath);
    if (await directory.exists()) {
      final files = directory
          .listSync()
          .where((item) => item.path.endsWith('.opus'))
          .toList();
      final fileDetails = <Map<String, dynamic>>[];
      for (final file in files) {
        final duration = await _getAudioDuration(file.path);
        fileDetails.add({'path': file.path, 'duration': duration});
      }
      return fileDetails;
    }
    return [];
  }

  Future<Duration?> _getAudioDuration(String path) async {
    try {
      return await _durationPlayer.setFilePath(path);
    } catch (e) {
      debugPrint("Error getting duration: $e");
      return null;
    }
  }

  void _refreshRecordedFiles() {
    setState(() {
      _recordedFiles = _getRecordedFiles();
    });
  }

  Future<void> _deleteRecording(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      if (_selectedFilePath == path) {
        _playerController.stopPlayer();
        setState(() {
          _selectedFilePath = null;
        });
      }
      _refreshRecordedFiles();
    }
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final myFlutterPath = p.join(appDocumentsDir.path, 'myflutter');
      await Directory(myFlutterPath).create(recursive: true);
      final filePath =
          p.join(myFlutterPath, 'audio_${DateTime.now().millisecondsSinceEpoch}.opus');

      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.opus),
          path: filePath);
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _startTimer();
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    _refreshRecordedFiles();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 20),
                Text(
                  _isRecording ? 'Recording...' : 'Tap to Record',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_isRecording)
                  Text(
                    _formatDuration(_recordDuration),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedFilePath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: aw.AudioFileWaveforms(
                      size:
                          Size(MediaQuery.of(context).size.width * 0.8, 100.0),
                      playerController: _playerController,
                      enableSeekGesture: true,
                      waveformType: aw.WaveformType.long,
                      playerWaveStyle: const aw.PlayerWaveStyle(
                        fixedWaveColor: Colors.grey,
                        liveWaveColor: Colors.blueAccent,
                        spacing: 6,
                      ),
                    ),
                  ),
                const Text('Recorded Files',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
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
                            final filePath = file['path'] as String;
                            final duration = file['duration'] as Duration?;
                            final isSelected = _selectedFilePath == filePath;

                            return ListTile(
                              title: Text(p.basename(filePath)),
                              subtitle: Text(duration != null
                                  ? '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                                  : '...'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(isSelected && _playerController.playerState == aw.PlayerState.playing ? Icons.pause : Icons.play_arrow),
                                    onPressed: () {
                                      if (isSelected && _playerController.playerState == aw.PlayerState.playing) {
                                         _playerController.pausePlayer();
                                      } else {
                                        _playerController
                                          .preparePlayer(
                                            path: filePath,
                                            shouldExtractWaveform: true,
                                          )
                                          .then((_) => _playerController
                                              .startPlayer());
                                      }
                                      setState(() {
                                        _selectedFilePath = filePath;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop),
                                    onPressed: () {
                                      _playerController.stopPlayer();
                                      setState(() {
                                        _selectedFilePath = null;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteRecording(filePath),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withAlpha(51),
                              onTap: () {
                                 _playerController
                                          .preparePlayer(
                                            path: filePath,
                                            shouldExtractWaveform: true,
                                          )
                                          .then((_) => _playerController
                                              .startPlayer());
                                      setState(() {
                                        _selectedFilePath = filePath;
                                      });
                              },
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
