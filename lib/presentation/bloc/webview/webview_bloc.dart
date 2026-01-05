import 'package:flutter_bloc/flutter_bloc.dart';
import 'webview_event.dart';
import 'webview_state.dart';

class WebViewBloc extends Bloc<WebViewEvent, WebViewState> {
  WebViewBloc() : super(const WebViewState()) {
    on<LoadUrlEvent>(_onLoadUrl);
    on<GoBackEvent>(_onGoBack);
    on<GoForwardEvent>(_onGoForward);
    on<ReloadEvent>(_onReload);
    on<StopLoadingEvent>(_onStopLoading);
    on<UrlChangedEvent>(_onUrlChanged);
    on<TitleChangedEvent>(_onTitleChanged);
    on<LoadingStartedEvent>(_onLoadingStarted);
    on<LoadingStoppedEvent>(_onLoadingStopped);
  }

  Future<void> _onLoadUrl(LoadUrlEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(currentUrl: event.url, isLoading: true));
  }

  Future<void> _onGoBack(GoBackEvent event, Emitter<WebViewState> emit) async {}

  Future<void> _onGoForward(GoForwardEvent event, Emitter<WebViewState> emit) async {}

  Future<void> _onReload(ReloadEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(isLoading: true));
  }

  Future<void> _onStopLoading(StopLoadingEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onUrlChanged(UrlChangedEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(currentUrl: event.url));
  }

  Future<void> _onTitleChanged(TitleChangedEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(title: event.title));
  }

  Future<void> _onLoadingStarted(LoadingStartedEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(isLoading: true));
  }

  Future<void> _onLoadingStopped(LoadingStoppedEvent event, Emitter<WebViewState> emit) async {
    emit(state.copyWith(isLoading: false));
  }
}
