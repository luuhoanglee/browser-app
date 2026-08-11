import 'package:browser_app/domain/entities/saved_page_entity.dart';
import 'package:browser_app/domain/repositories/saved_page_repository.dart';
import 'package:browser_app/features/library/bloc/saved_page_bloc.dart';
import 'package:browser_app/features/library/bloc/saved_page_event.dart';
import 'package:browser_app/features/library/widgets/saved_pages_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements SavedPageRepository {
  List<SavedPageEntity> items = [];

  @override
  Future<List<SavedPageEntity>> load() async => items;

  @override
  Future<void> save(List<SavedPageEntity> items) async {
    this.items = List.from(items);
  }
}

void main() {
  Widget buildSheet(SavedPageBloc bloc, {bool isIncognito = false}) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: SavedPagesSheet(
            currentTitle: 'Example',
            currentUrl: 'https://example.com',
            isIncognito: isIncognito,
            onOpen: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('saves the current page as a bookmark', (tester) async {
    final repository = _Repository();
    final bloc = SavedPageBloc(repository)..add(const SavedPagesLoadEvent());
    addTearDown(bloc.close);

    await tester.pumpWidget(buildSheet(bloc));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save bookmark'));
    await tester.pumpAndSettle();

    expect(repository.items, hasLength(1));
    expect(repository.items.single.url, 'https://example.com');
    expect(find.text('Example'), findsOneWidget);
  });

  testWidgets('does not allow saving from Incognito', (tester) async {
    final repository = _Repository();
    final bloc = SavedPageBloc(repository)..add(const SavedPagesLoadEvent());
    addTearDown(bloc.close);

    await tester.pumpWidget(buildSheet(bloc, isIncognito: true));
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(find.textContaining('disabled in Incognito'), findsOneWidget);
    expect(repository.items, isEmpty);
  });
}
