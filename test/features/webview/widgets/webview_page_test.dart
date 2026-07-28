import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/features/webview/widgets/webview_page.dart';

void main() {
  group('navigatorPlatformForWebView', () {
    test('reports an Android-compatible platform for Android WebView', () {
      expect(navigatorPlatformForWebView(isIOS: false), equals('Linux armv8l'));
    });

    test('keeps the iPhone platform for iOS WebView', () {
      expect(navigatorPlatformForWebView(isIOS: true), equals('iPhone'));
    });
  });
}
