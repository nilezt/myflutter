import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/preview_screen.dart';

import 'preview_screen_test.mocks.dart';

@GenerateMocks([File])
void main() {
  // Create a mock for the file to avoid file system access in tests
  final mockFile = MockFile();

  testWidgets('Renders PreviewScreen', (WidgetTester tester) async {
    // Stub the path getter
    when(mockFile.path).thenReturn('test/test_image.jpg');

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: PreviewScreen(imagePath: mockFile.path),
    ));

    // Verify that the title is rendered
    expect(find.text('Preview'), findsOneWidget);

    // Verify that the save and retake picture buttons are rendered.
    expect(find.text('Save Picture'), findsOneWidget);
    expect(find.text('Retake Picture'), findsOneWidget);
  });
}
