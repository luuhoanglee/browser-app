import 'dart:convert';

import '../../../domain/entities/saved_page_entity.dart';

class BookmarkHtmlCodec {
  static String encode(List<SavedPageEntity> items) {
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
      ..writeln(
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
      )
      ..writeln('<TITLE>Pardix Saved Pages</TITLE>')
      ..writeln('<H1>Pardix Saved Pages</H1>')
      ..writeln('<DL><p>');
    final grouped = <String, List<SavedPageEntity>>{};
    for (final item in items) {
      final root = item.collection == SavedPageCollection.bookmarks
          ? 'Bookmarks'
          : 'Reading List';
      final key = item.folder.isEmpty ? root : '$root / ${item.folder}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    for (final entry in grouped.entries) {
      buffer
        ..writeln('  <DT><H3>${_escape(entry.key)}</H3>')
        ..writeln('  <DL><p>');
      for (final item in entry.value) {
        final seconds = item.createdAt.millisecondsSinceEpoch ~/ 1000;
        buffer.writeln(
          '    <DT><A HREF="${_escape(item.url)}" ADD_DATE="$seconds" '
          'PARDIX_COLLECTION="${item.collection.name}" '
          'PARDIX_READ="${item.isRead}">${_escape(item.title)}</A>',
        );
      }
      buffer.writeln('  </DL><p>');
    }
    buffer.writeln('</DL><p>');
    return buffer.toString();
  }

  static List<SavedPageEntity> decode(String html) {
    final items = <SavedPageEntity>[];
    var currentFolder = '';
    final folderPattern = RegExp(r'<H3[^>]*>(.*?)</H3>', caseSensitive: false);
    final anchorPattern = RegExp(
      r'<A\s+([^>]*)>(.*?)</A>',
      caseSensitive: false,
    );
    final attributePattern = RegExp(
      r'''([A-Z_]+)\s*=\s*["']([^"']*)["']''',
      caseSensitive: false,
    );
    for (final line in const LineSplitter().convert(html)) {
      final folderMatch = folderPattern.firstMatch(line);
      if (folderMatch != null) {
        currentFolder = _unescape(_stripTags(folderMatch.group(1)!));
      }
      final anchorMatch = anchorPattern.firstMatch(line);
      if (anchorMatch == null) continue;
      final attributes = <String, String>{};
      for (final match in attributePattern.allMatches(anchorMatch.group(1)!)) {
        attributes[match.group(1)!.toUpperCase()] = _unescape(match.group(2)!);
      }
      final url = attributes['HREF']?.trim() ?? '';
      final uri = Uri.tryParse(url);
      if (url.isEmpty ||
          uri == null ||
          !{'http', 'https'}.contains(uri.scheme)) {
        continue;
      }
      final rawCollection = attributes['PARDIX_COLLECTION'];
      final collection =
          rawCollection == SavedPageCollection.readingList.name ||
              currentFolder.toLowerCase().startsWith('reading list')
          ? SavedPageCollection.readingList
          : SavedPageCollection.bookmarks;
      final folderParts = currentFolder.split('/');
      final folder = folderParts.length > 1
          ? folderParts.skip(1).join('/').trim()
          : (currentFolder == 'Bookmarks' || currentFolder == 'Reading List'
                ? ''
                : currentFolder);
      final seconds = int.tryParse(attributes['ADD_DATE'] ?? '');
      final createdAt = seconds == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      final title = _unescape(_stripTags(anchorMatch.group(2)!)).trim();
      items.add(
        SavedPageEntity(
          id: '${createdAt.microsecondsSinceEpoch}_${url.hashCode.abs()}',
          title: title.isEmpty ? uri.host : title,
          url: url,
          folder: folder,
          collection: collection,
          isRead: attributes['PARDIX_READ'] == 'true',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }
    return items;
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _unescape(String value) => value
      .replaceAll('&quot;', '"')
      .replaceAll('&gt;', '>')
      .replaceAll('&lt;', '<')
      .replaceAll('&amp;', '&');

  static String _stripTags(String value) =>
      value.replaceAll(RegExp(r'<[^>]*>'), '');
}
