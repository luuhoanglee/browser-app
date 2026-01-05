abstract class WebViewEvent {}

class LoadUrlEvent extends WebViewEvent {
  final String url;

  LoadUrlEvent(this.url);
}

class GoBackEvent extends WebViewEvent {}

class GoForwardEvent extends WebViewEvent {}

class ReloadEvent extends WebViewEvent {}

class StopLoadingEvent extends WebViewEvent {}

class UrlChangedEvent extends WebViewEvent {
  final String url;

  UrlChangedEvent(this.url);
}

class TitleChangedEvent extends WebViewEvent {
  final String title;

  TitleChangedEvent(this.title);
}

class LoadingStartedEvent extends WebViewEvent {}

class LoadingStoppedEvent extends WebViewEvent {}
