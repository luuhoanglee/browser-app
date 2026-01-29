import '../../../domain/entities/tab_entity.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  final bool forceUpdate;

  UpdateTabEvent(this.tab, {this.skipCache = false, this.forceUpdate = false});
}

class AddLoadedResourceEvent extends TabEvent {
  final String tabId;
  final LoadedResource resource;

  AddLoadedResourceEvent(this.tabId, this.resource);
}

class ClearLoadedResourcesEvent extends TabEvent {
  final String tabId;

  ClearLoadedResourcesEvent(this.tabId);
}
