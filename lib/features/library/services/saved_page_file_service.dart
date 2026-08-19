import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../domain/entities/saved_page_entity.dart';
import 'bookmark_html_codec.dart';

class SavedPageFileService {
  static Future<List<SavedPageEntity>?> importHtml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) return const [];
    return BookmarkHtmlCodec.decode(utf8.decode(bytes, allowMalformed: true));
  }

  static Future<bool> exportHtml(List<SavedPageEntity> items) async {
    final bytes = Uint8List.fromList(
      utf8.encode(BookmarkHtmlCodec.encode(items)),
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export saved pages',
      fileName: 'pardix-bookmarks.html',
      type: FileType.custom,
      allowedExtensions: const ['html'],
      bytes: bytes,
    );
    if (path == null) return false;
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return true;
  }
}
