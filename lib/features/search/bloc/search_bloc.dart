import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/logger/analytics_event.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:browser_app/features/search/search_service.dart';
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
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadTrendingEvent>(_onLoadTrending);
    on<LoadSuggestionsEvent>(_onLoadSuggestions);
    // Load initial data using events
    add(LoadHistoryEvent());
    add(LoadTrendingEvent());
  }

  void _onUpdateQuery(UpdateQueryEvent event, Emitter<SearchState> emit) {
    emit(state.copyWith(query: event.query));
    // Load suggestions khi query thay đổi
    if (event.query.isNotEmpty) {
      add(LoadSuggestionsEvent(event.query));
    } else {
      emit(state.copyWith(searchSuggestions: []));
    }
  }

  Future<void> _onLoadSuggestions(
    LoadSuggestionsEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(isLoadingSuggestions: true));
    try {
      final suggestions = await SearchService.getSuggestions(
        event.query,
        engine: state.selectedEngine,
      );
      emit(
        state.copyWith(
          searchSuggestions: suggestions,
          isLoadingSuggestions: false,
        ),
      );
    } catch (e) {
      print('🎯 [Bloc] Error loading suggestions: $e');
      emit(state.copyWith(isLoadingSuggestions: false));
    }
  }

  void _onSetEngine(SetEngineEvent event, Emitter<SearchState> emit) {
    SearchService.setDefaultEngine(event.engine);
    emit(state.copyWith(selectedEngine: event.engine));
    AppLogger.event(
      AnalyticsEvent.searchEngineChanged,
      params: {AnalyticsParam.engine: event.engine.name},
    );
    // Reload trending khi thay đổi engine
    add(LoadTrendingEvent());
  }

  void _onPerformSearch(
    PerformSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query ?? state.query;
    if (query.isEmpty) return;

    if (!event.skipHistory) {
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
    }

    // Sử dụng keyword search
    final url = SearchService.buildSearchUrl(query);
    AppLogger.event(
      AnalyticsEvent.searchPerformed,
      params: {
        AnalyticsParam.engine: state.selectedEngine.name,
        AnalyticsParam.queryLength: query.length,
      },
    );
    emit(state.copyWith(resultUrl: url, query: query));
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }

  void _onClearSearchHistory(
    ClearSearchHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    await StorageService.clearSearchHistory();
    AppLogger.event(AnalyticsEvent.searchHistoryCleared);
    emit(state.copyWith(searchHistory: []));
  }

  void _onRemoveSearchHistory(
    RemoveSearchHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    final updatedHistory = List<String>.from(state.searchHistory);
    updatedHistory.remove(event.query);
    await StorageService.saveSearchHistory(updatedHistory);
    emit(state.copyWith(searchHistory: updatedHistory));
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    final history = await StorageService.loadSearchHistory();
    emit(state.copyWith(searchHistory: history));
  }

  Future<void> _onLoadTrending(
    LoadTrendingEvent event,
    Emitter<SearchState> emit,
  ) async {
    print('🎯 [Bloc] LoadTrendingEvent received');
    emit(state.copyWith(isLoadingTrending: true));
    try {
      final trending = await SearchService.fetchTrending(
        engine: state.selectedEngine,
      );
      print(
        '🎯 [Bloc] Fetched ${trending.length} trending searches for ${state.selectedEngine}',
      );
      print('🎯 [Bloc] Trending list: $trending');
      emit(
        state.copyWith(trendingSearches: trending, isLoadingTrending: false),
      );
      print(
        '🎯 [Bloc] State updated: trendingSearches = ${state.trendingSearches.length}',
      );
    } catch (e) {
      print('🎯 [Bloc] Error loading trending: $e');
      emit(state.copyWith(isLoadingTrending: false));
    }
  }

  /// Get search URL without emitting state (cho immediate use)
  String? getSearchUrl([String? query]) {
    final q = query ?? state.query;
    if (q.isEmpty) return null;
    return SearchService.buildSearchUrl(q);
  }
}
