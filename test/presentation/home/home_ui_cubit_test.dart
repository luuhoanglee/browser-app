import 'package:flutter_test/flutter_test.dart';
import 'package:browser_app/presentation/pages/home/bloc/home_ui_cubit.dart';

/// Cubit tests for [HomeUiCubit].
///
/// The mini URL bar (issue #21) is shown whenever the toolbar is hidden, so the
/// hide/show transitions that drive that swap are covered here.
void main() {
  group('HomeUiCubit', () {
    late HomeUiCubit cubit;

    setUp(() => cubit = HomeUiCubit());
    tearDown(() => cubit.close());

    test('starts with the toolbar visible and no scroll offset', () {
      expect(cubit.state.isToolbarVisible, isTrue);
      expect(cubit.state.lastScrollY, 0);
    });

    test('hides the toolbar when scrolling down past the threshold', () {
      cubit.handleScrollChange(300);

      expect(cubit.state.isToolbarVisible, isFalse);
      expect(cubit.state.lastScrollY, 300);
    });

    test('keeps the toolbar visible while scroll stays under the threshold', () {
      cubit.handleScrollChange(150);

      expect(cubit.state.isToolbarVisible, isTrue);
      expect(cubit.state.lastScrollY, 150);
    });

    test('shows the toolbar again when scrolling back up', () async {
      cubit.handleScrollChange(300); // hide
      expect(cubit.state.isToolbarVisible, isFalse);

      cubit.handleScrollChange(250); // scroll up
      expect(cubit.state.isToolbarVisible, isTrue);
      expect(cubit.state.lastScrollY, 250);
    });

    test('emits hide then show in order', () {
      expectLater(
        cubit.stream.map((s) => s.isToolbarVisible),
        emitsInOrder([false, true]),
      );

      cubit.handleScrollChange(300); // hide
      cubit.handleScrollChange(250); // show
    });

    test('resetScrollState restores the default visible state', () {
      cubit.handleScrollChange(300);
      expect(cubit.state.isToolbarVisible, isFalse);

      cubit.resetScrollState();
      expect(cubit.state.isToolbarVisible, isTrue);
      expect(cubit.state.lastScrollY, 0);
    });
  });
}
