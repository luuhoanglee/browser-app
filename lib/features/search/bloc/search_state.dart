import '../../../features/search/search_service.dart';
import 'package:equatable/equatable.dart';

class SearchState extends Equatable {
  final String query;
  final SearchEngine selectedEngine;
  final String? resultUrl;
  final List<String> searchHistory;

  const SearchState({
    this.query = '',
    this.selectedEngine = SearchEngine.google,
    this.resultUrl,
    this.searchHistory = const [],
  });

  SearchState copyWith({
    String? query,
    SearchEngine? selectedEngine,
    String? resultUrl,
    List<String>? searchHistory,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedEngine: selectedEngine ?? this.selectedEngine,
      resultUrl: resultUrl ?? this.resultUrl,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }

  @override
  List<Object?> get props => [query, selectedEngine, resultUrl, searchHistory];
}
