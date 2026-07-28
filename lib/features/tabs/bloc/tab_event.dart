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

class ToggleIncognitoModeEvent extends TabEvent {}

class EnableSplitViewEvent extends TabEvent {
  final String secondaryTabId;

  EnableSplitViewEvent(this.secondaryTabId);
}

class DisableSplitViewEvent extends TabEvent {}

class SetSplitSecondaryTabEvent extends TabEvent {
  final String secondaryTabId;

  SetSplitSecondaryTabEvent(this.secondaryTabId);
}

class UpdateSplitRatioEvent extends TabEvent {
  final double ratio;

  UpdateSplitRatioEvent(this.ratio);
}

/// Points the toolbar (URL bar, back/forward, reload, progress, search, media)
/// at one of the two split panes. Dispatched when the user touches a pane, so
/// both pages are operable instead of only the primary one.
class FocusSplitPaneEvent extends TabEvent {
  final String tabId;

  FocusSplitPaneEvent(this.tabId);
}

/// Toggles which pane owns audio (issue #20). Tapping the pane that already has
/// sound mutes everything; tapping any other pane gives it sound and mutes the
/// rest, guaranteeing at most one pane is unmuted.
class SetAudioTabEvent extends TabEvent {
  final String tabId;

  SetAudioTabEvent(this.tabId);
}
