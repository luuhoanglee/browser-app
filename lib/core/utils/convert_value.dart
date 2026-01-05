import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:string_validator/string_validator.dart';

class ConvertValue {
  static double s2d(String? value) {
    if (value == null || !isNumeric(value)) return 0.0;
    return double.parse(value);
  }
  static List<T> stringList2enum<T extends Enum>(List<String> strings, List<T> values) {
    return strings
        .map((str) => values.firstWhere(
          (e) => e.name == str,
      orElse: () => throw ArgumentError('Invalid enum value: $str'),
    ))
        .toList();
  }
  static List<String> enum2StringList<T extends Enum>(List<T> enumList) {
    return enumList.map((e) => e.name).toList();
  }

  static PlatformFile fileToPlatformFile(File file) {
    final bytes = file.readAsBytesSync(); // Optional (only if you need bytes)
    final fileStat = file.statSync();

    return PlatformFile(
      name: file.uri.pathSegments.last,
      size: fileStat.size,
      path: file.path,
      bytes: bytes, // you can omit this if not needed
    );
  }
}