import 'package:browser_app/domain/entities/saved_page_entity.dart';
import 'package:browser_app/features/library/services/bookmark_html_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round trips bookmark and reading-list metadata', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final source = [
      SavedPageEntity(
        id: 'bookmark',
        title: 'News & Updates',
        url: 'https://example.com/?a=1&b=2',
        folder: 'Daily',
        collection: SavedPageCollection.bookmarks,
        isRead: false,
        createdAt: now,
        updatedAt: now,
      ),
      SavedPageEntity(
        id: 'reading',
        title: 'Long read',
        url: 'https://example.org/article',
        folder: 'Weekend',
        collection: SavedPageCollection.readingList,
        isRead: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final decoded = BookmarkHtmlCodec.decode(BookmarkHtmlCodec.encode(source));

    expect(decoded, hasLength(2));
    expect(decoded.first.title, 'News & Updates');
    expect(decoded.first.folder, 'Daily');
    expect(decoded.last.collection, SavedPageCollection.readingList);
    expect(decoded.last.isRead, isTrue);
  });

  test('imports a standard Netscape bookmark file', () {
    const html = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<DL><p>
  <DT><H3>Imported</H3>
  <DL><p>
    <DT><A HREF="https://flutter.dev" ADD_DATE="1700000000">Flutter</A>
  </DL><p>
</DL><p>
''';

    final decoded = BookmarkHtmlCodec.decode(html);

    expect(decoded.single.title, 'Flutter');
    expect(decoded.single.folder, 'Imported');
    expect(decoded.single.collection, SavedPageCollection.bookmarks);
  });

  test('ignores malformed and non-http URLs', () {
    const html = '''
<DT><A HREF="javascript:alert(1)">Bad</A>
<DT><A HREF="not a url">Also bad</A>
<DT><A HREF="https://safe.example">Safe</A>
''';

    final decoded = BookmarkHtmlCodec.decode(html);

    expect(decoded.map((item) => item.title), ['Safe']);
  });
}
