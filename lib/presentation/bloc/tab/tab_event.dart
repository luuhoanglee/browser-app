import '../../../domain/entities/tab_entity.dart';

abstract class TabEvent {}

class AddTabEvent extends TabEvent {}

class RemoveTabEvent extends TabEvent {
  final String tabId;

  RemoveTabEvent(this.tabId);
}

class SelectTabEvent extends TabEvent {
  final String tabId;

  SelectTabEvent(this.tabId);
}

class UpdateTabEvent extends TabEvent {
  final TabEntity tab;
  final bool skipCache;

  UpdateTabEvent(this.tab, {this.skipCache = false});
}
