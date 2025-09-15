import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PreviewScreen extends StatelessWidget {
  final String imagePath;
  final bool isTemporary;

  const PreviewScreen(
      {super.key, required this.imagePath, this.isTemporary = true});

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(File(imagePath)),
            ),
          ),
          if (isTemporary)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: buttonStyle,
                    onPressed: () {
                      // Discard the temporary image and go back to the camera
                      Navigator.of(context).pop();
                    },
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    style: buttonStyle,
                    onPressed: () async {
                      final appDocumentsDir =
                          await getApplicationDocumentsDirectory();
                      final picturesPath = p.join(appDocumentsDir.path, 'pictures');
                      await Directory(picturesPath).create(recursive: true);
                      final formattedDate =
                          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                      final newImagePath = p.join(picturesPath, 'image_$formattedDate.jpg');
                      
                      // Save the image
                      await File(imagePath).copy(newImagePath);

                      if (context.mounted) {
                        // Go back to the home screen
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
