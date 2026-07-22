import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logo assets are bundled as PNG files', () async {
    final launcherIcon = await rootBundle.load('assets/logo/logo.png');

    expect(_isPng(launcherIcon), isTrue);
    expect(launcherIcon.lengthInBytes, greaterThan(0));
  });
}

bool _isPng(ByteData data) {
  const pngSignature = [0x89, 0x50, 0x4e, 0x47];
  final bytes = data.buffer.asUint8List(0, pngSignature.length);

  for (var index = 0; index < pngSignature.length; index++) {
    if (bytes[index] != pngSignature[index]) {
      return false;
    }
  }

  return true;
}
