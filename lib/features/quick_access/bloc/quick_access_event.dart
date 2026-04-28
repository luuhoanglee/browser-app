import '../models/quick_access_site.dart';

abstract class QuickAccessEvent {
  const QuickAccessEvent();
}

class QuickAccessLoadEvent extends QuickAccessEvent {
  const QuickAccessLoadEvent();
}

class QuickAccessAddEvent extends QuickAccessEvent {
  final QuickAccessSite site;
  const QuickAccessAddEvent(this.site);
}

class QuickAccessRemoveEvent extends QuickAccessEvent {
  final String id;
  const QuickAccessRemoveEvent(this.id);
}

class QuickAccessReorderEvent extends QuickAccessEvent {
  final int oldIndex;
  final int newIndex;
  const QuickAccessReorderEvent(this.oldIndex, this.newIndex);
}
