import 'package:flutter_bloc/flutter_bloc.dart';
import '../search_service.dart';
import '../../../../data/services/storage_service.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchState()) {
    on<UpdateQueryEvent>(_onUpdateQuery);
    on<SetEngineEvent>(_onSetEngine);
    on<PerformSearchEvent>(_onPerformSearch);
    on<ClearSearchEvent>(_onClearSearch);
    on<ClearSearchHistoryEvent>(_onClearSearchHistory);
    on<RemoveSearchHistoryEvent>(_onRemoveSearchHistory);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.loadSearchHistory();
    emit(state.copyWith(searchHistory: history));
  }

  void _onUpdateQuery(UpdateQueryEvent event, Emitter<SearchState> emit) {
    emit(state.copyWith(query: event.query));
  }

  void _onSetEngine(SetEngineEvent event, Emitter<SearchState> emit) {
    SearchService.setDefaultEngine(event.engine);
    emit(state.copyWith(selectedEngine: event.engine));
  }

  void _onPerformSearch(PerformSearchEvent event, Emitter<SearchState> emit) async {
    final query = event.query ?? state.query;
    if (query.isEmpty) return;

    // Thêm vào search history
    final updatedHistory = List<String>.from(state.searchHistory);
    if (!updatedHistory.contains(query)) {
      updatedHistory.insert(0, query);
      // Giới hạn 50 mục
      if (updatedHistory.length > 50) {
        updatedHistory.removeLast();
      }
      await StorageService.saveSearchHistory(updatedHistory);
      emit(state.copyWith(searchHistory: updatedHistory));
    }

    // Sử dụng keyword search
    final url = SearchService.formatUrlWithKeyword(query);
    emit(state.copyWith(resultUrl: url, query: query));
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }

  void _onClearSearchHistory(ClearSearchHistoryEvent event, Emitter<SearchState> emit) async {
    await StorageService.clearSearchHistory();
    emit(state.copyWith(searchHistory: []));
  }

  void _onRemoveSearchHistory(RemoveSearchHistoryEvent event, Emitter<SearchState> emit) async {
    final updatedHistory = List<String>.from(state.searchHistory);
    updatedHistory.remove(event.query);
    await StorageService.saveSearchHistory(updatedHistory);
    emit(state.copyWith(searchHistory: updatedHistory));
  }

  /// Get search URL without emitting state (cho immediate use)
  String? getSearchUrl([String? query]) {
    final q = query ?? state.query;
    if (q.isEmpty) return null;
    return SearchService.formatUrlWithKeyword(q);
  }
}
