// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/preview_screen.dart';

void main() {
  // Create a temporary directory for testing
  final Directory testDir = Directory('test/temp_images');

  setUp(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Verify MyHomePage has Take a Picture and Record Audio buttons',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        cameras: const [
          CameraDescription(
            name: 'cam',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          )
        ],
      ),
    ));

    expect(find.text('Take a Picture'), findsOneWidget);
    expect(find.text('Record Audio'), findsOneWidget);
  });

  testWidgets('PreviewScreen shows Retake and Save buttons for temporary images',
      (WidgetTester tester) async {
    // Create a dummy image file
    final File imageFile = File('${testDir.path}/temp.jpg');
    imageFile.writeAsStringSync('test');

    await tester.pumpWidget(MaterialApp(
      home: PreviewScreen(
        imagePath: imageFile.path,
        isTemporary: true,
      ),
    ));

    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets(
      'PreviewScreen does not show buttons for non-temporary (saved) images',
      (WidgetTester tester) async {
    // Create a dummy image file
    final File imageFile = File('${testDir.path}/saved.jpg');
    imageFile.writeAsStringSync('test');

    await tester.pumpWidget(MaterialApp(
      home: PreviewScreen(
        imagePath: imageFile.path,
        isTemporary: false,
      ),
    ));

    // No buttons should be present when viewing a saved image
    expect(find.text('Retake'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });
}
