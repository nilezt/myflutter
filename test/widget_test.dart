
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Renders MyHomePage', (WidgetTester tester) async {
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

    // Verify that the title is rendered.
    expect(find.text('Myflutter App'), findsOneWidget);

    // Verify that the buttons are rendered.
    expect(find.text('Take a Picture'), findsOneWidget);
    expect(find.text('Record Audio'), findsOneWidget);
  });
}
