
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Renders NoCamerasScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: NoCamerasScreen(),
    ));

    // Verify that the title is rendered.
    expect(find.text('Myflutter App'), findsOneWidget);

    // Verify that the message is rendered.
    expect(find.text('No cameras found on this device.'), findsOneWidget);
  });
}
