import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('Renders RecordAudioScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: RecordAudioScreen(),
    ));

    // Verify that the title is rendered.
    expect(find.text('Record Audio'), findsOneWidget);

    // Verify that the record button is rendered.
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Verify that the recorded files title is rendered.
    expect(find.text('Recorded Files'), findsOneWidget);
  });
}
