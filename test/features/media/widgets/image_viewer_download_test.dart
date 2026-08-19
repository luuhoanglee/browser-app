import 'package:browser_app/features/download/bloc/download_event.dart';
import 'package:browser_app/features/media/widgets/image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('download button queues the currently visible image', (
    tester,
  ) async {
    DownloadStartEvent? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: ImageViewerPage(
          imageUrls: const [
            'https://cdn.example.com/first.jpg',
            'https://cdn.example.com/folder/second.png?token=abc',
          ],
          initialIndex: 1,
          onDownloadRequested: (event) => captured = event,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.download));
    await tester.pump();

    expect(captured?.url, contains('/folder/second.png'));
    expect(captured?.customFileName, 'second.png');
    expect(find.text('Download added to the queue.'), findsOneWidget);
  });
}
