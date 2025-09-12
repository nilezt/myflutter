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
          Image.file(File(imagePath)),
          ElevatedButton(
            onPressed: () async {
              final picturesPath = p.join(
                (await getApplicationDocumentsDirectory()).path,
                'pictures',
              );
              final newPath = p.join(picturesPath, p.basename(imagePath));
              await Directory(picturesPath).create(recursive: true);
              await File(imagePath).rename(newPath);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Picture saved to $newPath'),
                  ),
                );
              }
            },
            child: const Text('Save Picture'),
          ),
        ],
      ),
    );
  }
}
