import 'package:flutter_bloc/flutter_bloc.dart';

class HomeUiState {
  final bool isToolbarVisible;
  final int lastScrollY;

  const HomeUiState({this.isToolbarVisible = true, this.lastScrollY = 0});

  HomeUiState copyWith({bool? isToolbarVisible, int? lastScrollY}) {
    return HomeUiState(
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      lastScrollY: lastScrollY ?? this.lastScrollY,
    );
  }
}

class HomeUiCubit extends Cubit<HomeUiState> {
  HomeUiCubit() : super(const HomeUiState());

  static const int _hideToolbarThreshold = 200;

  void handleScrollChange(int scrollY) {
    final shouldHide =
        scrollY > state.lastScrollY &&
        scrollY > _hideToolbarThreshold &&
        state.isToolbarVisible;
    final shouldShow = scrollY < state.lastScrollY && !state.isToolbarVisible;

    if (shouldHide || shouldShow) {
      emit(state.copyWith(isToolbarVisible: shouldShow, lastScrollY: scrollY));
      return;
    }

    emit(state.copyWith(lastScrollY: scrollY));
  }

  void resetScrollState() {
    if (state.isToolbarVisible && state.lastScrollY == 0) return;
    emit(const HomeUiState());
  }
}
