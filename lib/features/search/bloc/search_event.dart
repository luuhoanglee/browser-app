import '../../../features/search/search_service.dart';

abstract class SearchEvent {}

class UpdateQueryEvent extends SearchEvent {
  final String query;

  UpdateQueryEvent(this.query);
}

class SetEngineEvent extends SearchEvent {
  final SearchEngine engine;

  SetEngineEvent(this.engine);
}

class PerformSearchEvent extends SearchEvent {
  final String? query;

  PerformSearchEvent([this.query]);
}

class ClearSearchEvent extends SearchEvent {}

class ClearSearchHistoryEvent extends SearchEvent {}

class RemoveSearchHistoryEvent extends SearchEvent {
  final String query;

  RemoveSearchHistoryEvent(this.query);
}

class LoadHistoryEvent extends SearchEvent {}

class LoadTrendingEvent extends SearchEvent {}

class LoadSuggestionsEvent extends SearchEvent {
  final String query;

  LoadSuggestionsEvent(this.query);
}
