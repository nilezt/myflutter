
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Renders TakePictureScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: TakePictureScreen(
        camera: const CameraDescription(
          name: 'cam',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ),
    ));

    // Verify that the title is rendered.
    expect(find.text('Take a picture'), findsOneWidget);

    // Verify that the loading indicator is rendered.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify that the take picture button is rendered.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
