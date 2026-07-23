import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:browser_app/domain/entities/tab_entity.dart';
import 'package:browser_app/presentation/pages/home/bloc/home_ui_cubit.dart';
import 'package:browser_app/presentation/pages/home/widgets/mini_url_bar.dart';

/// E2E (integration) coverage for issue #21.
///
/// Reproduces the home page's bottom region: a white [Scaffold] whose bottom
/// toolbar swaps between the full bar and the [MiniUrlBar] via the same
/// [HomeUiCubit] scroll logic the app uses. When the toolbar hides, the mini
/// bar must hug the bottom of the screen — the page content should fill the
/// space right down to the top of the mini bar, leaving no tall white band.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tab = TabEntity(
    id: 'tab-1',
    url: 'https://javhd.free/watch',
    title: 'demo',
    index: 0,
  );

  // A notched, gesture-nav device profile: 47px status bar, 34px nav inset.
  const notch = EdgeInsets.only(top: 47, bottom: 34);

  Widget app(HomeUiCubit cubit) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(padding: notch),
        child: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                Expanded(
                  child: Container(
                    key: const ValueKey('web_content'),
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const Text(
                      'web content',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                BlocBuilder<HomeUiCubit, HomeUiState>(
                  buildWhen: (p, c) =>
                      p.isToolbarVisible != c.isToolbarVisible,
                  builder: (context, state) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: state.isToolbarVisible
                        ? Container(
                            key: const ValueKey('full_toolbar'),
                            height: 140,
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: const Text('full toolbar'),
                          )
                        : MiniUrlBar(
                            key: const ValueKey('mini_toolbar'),
                            activeTab: tab,
                            controller: null,
                            onTap: () {},
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'hiding the toolbar leaves no white band above the mini URL bar',
    (tester) async {
      final cubit = HomeUiCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(app(cubit));
      await tester.pumpAndSettle();

      // Full toolbar shown initially.
      expect(find.byKey(const ValueKey('full_toolbar')), findsOneWidget);
      expect(find.byType(MiniUrlBar), findsNothing);

      // Scroll down far enough to hide the toolbar.
      cubit.handleScrollChange(400);
      await tester.pumpAndSettle();

      // Mini bar is now shown, full bar gone.
      expect(find.byType(MiniUrlBar), findsOneWidget);
      expect(find.byKey(const ValueKey('full_toolbar')), findsNothing);

      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      final miniTop = tester.getTopLeft(find.byType(MiniUrlBar)).dy;
      final miniBottom = tester.getBottomLeft(find.byType(MiniUrlBar)).dy;
      final contentBottom =
          tester.getBottomLeft(find.byKey(const ValueKey('web_content'))).dy;

      // The mini bar strip is thin — no giant blank region.
      expect(
        miniBottom - miniTop,
        lessThan(120),
        reason: 'mini bar must hug its content, not the whole toolbar height',
      );

      // Page content fills right down to the top of the mini bar (no gap).
      expect((contentBottom - miniTop).abs(), lessThan(1.0));

      // The mini bar reaches the bottom of the screen.
      expect((miniBottom - screenHeight).abs(), lessThan(1.0));

      // The pill respects the 34px bottom gesture inset.
      final pillBottom = tester.getBottomLeft(find.text('javhd.free')).dy;
      expect(miniBottom - pillBottom, greaterThan(30));
    },
  );
}
