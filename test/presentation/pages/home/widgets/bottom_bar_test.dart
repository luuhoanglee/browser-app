import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/domain/entities/tab_entity.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';
import 'package:browser_app/presentation/pages/home/widgets/bottom_bar.dart';

void main() {
  const tab = TabEntity(
    id: 'tab-1',
    url: 'https://example.com/page',
    title: 'Example',
    index: 0,
  );
  const tabState = TabState(tabs: [tab], activeTab: tab);

  Widget buildBottomBar(Size size) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          bottomNavigationBar: BottomBar(
            activeTab: tab,
            tabState: tabState,
            controller: null,
            onShowTabs: () {},
            onAddressBarTap: () {},
            onShowHistory: () {},
            onShowDownload: () {},
            onShowMedia: () {},
            onShowWarp: () {},
            isSearching: false,
            isMediaSheetOpen: false,
            searchController: TextEditingController(),
            searchFocusNode: FocusNode(),
            onSearch: (_) {},
            onBack: () {},
            onForward: () {},
            canGoBack: () async => false,
            canGoForward: () async => false,
          ),
        ),
      ),
    );
  }

  testWidgets('uses a compact single-row toolbar in landscape', (tester) async {
    await tester.pumpWidget(buildBottomBar(const Size(800, 360)));
    await tester.pump();

    expect(
      tester.getSize(find.byType(BottomBar)).height,
      lessThanOrEqualTo(52),
    );
    expect(find.text('example.com/page'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('keeps the two-row toolbar in portrait', (tester) async {
    await tester.pumpWidget(buildBottomBar(const Size(360, 800)));
    await tester.pump();

    expect(tester.getSize(find.byType(BottomBar)).height, greaterThan(90));
  });
}
