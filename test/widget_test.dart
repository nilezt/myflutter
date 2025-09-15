import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/preview_screen.dart';


void main() {
  // Since path_provider is used, we need to set up a mock handler
  // to avoid platform-specific errors in the test environment.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('MyHomePage UI Test', (WidgetTester tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(cameras: [const FakeCameraDescription(name: 'fake_camera')]),
    ));
    await tester.pump(); 

    // Verify that the AppBar title is correct.
    expect(find.text('Myflutter App'), findsOneWidget);

    // Verify that the "Take a Picture" and "Record Audio" buttons are present.
    expect(find.text('Take a Picture'), findsOneWidget);
    expect(find.text('Record Audio'), findsOneWidget);
  });

  testWidgets('RecordAudioScreen UI Test', (WidgetTester tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;

    // Build the RecordAudioScreen
    await tester.pumpWidget(const MaterialApp(
      home: RecordAudioScreen(),
    ));
    await tester.pump();

    // Verify the AppBar title.
    expect(find.text('Record Audio'), findsOneWidget);

    // Verify the "Recorded Files" text is present.
    expect(find.text('Recorded Files'), findsOneWidget);

    // Verify the initial "Tap to Record" text is present.
    expect(find.text('Tap to Record'), findsOneWidget);

    // Verify the record button icon is present.
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('PreviewScreen UI Test', (WidgetTester tester) async {
    // Since PreviewScreen deals with file paths, we need a mock path.
    // In a real test, you might use a temporary file.
    const String fakeImagePath = '/fake/path/image.jpg';

    // Test the temporary preview (with Save/Retake buttons)
    await tester.pumpWidget(const MaterialApp(
      home: PreviewScreen(
        imagePath: fakeImagePath,
        isTemporary: true,
      ),
    ));

    // The image itself will fail to load, which is expected in a test environment
    // without a real file system. We're testing the UI structure.
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}

// Corrected FakeCameraDescription for testing purposes.
class FakeCameraDescription implements CameraDescription {
  @override
  final String name;

  @override
  final CameraLensDirection lensDirection = CameraLensDirection.back;

  @override
  final int sensorOrientation = 0;

  const FakeCameraDescription({required this.name});

  @override
  CameraLensType get lensType => CameraLensType.wide; // Corrected line
}
