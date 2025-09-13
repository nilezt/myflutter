import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PreviewScreen extends StatelessWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          Expanded(child: Image.file(File(imagePath))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final picturesPath = p.join(
                      (await getApplicationDocumentsDirectory()).path,
                      'pictures',
                    );
                    final newPath = p.join(picturesPath, p.basename(imagePath));
                    await Directory(picturesPath).create(recursive: true);
                    await File(imagePath).rename(newPath);
                    
                    if (!context.mounted) return;

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Picture saved to $newPath'),
                      ),
                    );
                    // Pop back to the home screen after saving
                    navigator.popUntil((route) => route.isFirst);
                  },
                  child: const Text('Save Picture'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Just pop the screen to go back to the camera
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Retake Picture'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
