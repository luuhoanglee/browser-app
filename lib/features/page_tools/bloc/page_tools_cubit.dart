import 'package:flutter_bloc/flutter_bloc.dart';

class FindResultState {
  final int activeMatch;
  final int matchCount;

  const FindResultState({this.activeMatch = 0, this.matchCount = 0});
}

class PageToolsState {
  final Map<String, FindResultState> findResults;

  const PageToolsState({this.findResults = const {}});

  FindResultState resultFor(String tabId) =>
      findResults[tabId] ?? const FindResultState();
}

class PageToolsCubit extends Cubit<PageToolsState> {
  PageToolsCubit() : super(const PageToolsState());

  void updateFindResult(String tabId, int activeMatch, int matchCount) {
    emit(
      PageToolsState(
        findResults: {
          ...state.findResults,
          tabId: FindResultState(
            activeMatch: matchCount == 0 ? 0 : activeMatch + 1,
            matchCount: matchCount,
          ),
        },
      ),
    );
  }

  void clearFindResult(String tabId) {
    final next = Map<String, FindResultState>.from(state.findResults)
      ..remove(tabId);
    emit(PageToolsState(findResults: next));
  }
}
