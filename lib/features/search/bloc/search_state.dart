import '../../../features/search/search_service.dart';
import 'package:equatable/equatable.dart';

class SearchState extends Equatable {
  final String query;
  final SearchEngine selectedEngine;
  final String? resultUrl;
  final List<String> searchHistory;
  final List<String> trendingSearches;
  final bool isLoadingTrending;
  final List<String> searchSuggestions;
  final bool isLoadingSuggestions;

  const SearchState({
    this.query = '',
    this.selectedEngine = SearchEngine.google,
    this.resultUrl,
    this.searchHistory = const [],
    this.trendingSearches = const [],
    this.isLoadingTrending = false,
    this.searchSuggestions = const [],
    this.isLoadingSuggestions = false,
  });

  SearchState copyWith({
    String? query,
    SearchEngine? selectedEngine,
    String? resultUrl,
    List<String>? searchHistory,
    List<String>? trendingSearches,
    bool? isLoadingTrending,
    List<String>? searchSuggestions,
    bool? isLoadingSuggestions,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedEngine: selectedEngine ?? this.selectedEngine,
      resultUrl: resultUrl ?? this.resultUrl,
      searchHistory: searchHistory ?? this.searchHistory,
      trendingSearches: trendingSearches ?? this.trendingSearches,
      isLoadingTrending: isLoadingTrending ?? this.isLoadingTrending,
      searchSuggestions: searchSuggestions ?? this.searchSuggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
    );
  }

  @override
  List<Object?> get props => [query, selectedEngine, resultUrl, searchHistory, trendingSearches, isLoadingTrending, searchSuggestions, isLoadingSuggestions];
}
