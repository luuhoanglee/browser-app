class WebViewState {
  final String? currentUrl;
  final String? title;
  final bool isLoading;
  final bool canGoBack;
  final bool canGoForward;

  const WebViewState({
    this.currentUrl,
    this.title,
    this.isLoading = false,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  WebViewState copyWith({
    String? currentUrl,
    String? title,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    return WebViewState(
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}
