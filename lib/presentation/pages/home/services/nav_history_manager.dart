/// Manages per-tab navigation history independently of the browser's
/// built-in WebView history stack.
class NavHistoryManager {
  final Map<String, List<String>> _history = {};
  final Map<String, int> _index = {};

  void _ensure(String tabId) {
    _history.putIfAbsent(tabId, () => []);
    _index.putIfAbsent(tabId, () => -1);
  }

  /// Records [url] in the history for [tabId], trimming any forward entries.
  void addUrl(String tabId, String url) {
    _ensure(tabId);
    final hist = _history[tabId]!;
    final idx = _index[tabId]!;

    if (idx < hist.length - 1) {
      _history[tabId] = hist.sublist(0, idx + 1);
    }
    if (idx < 0 || hist[idx] != url) {
      _history[tabId]!.add(url);
      _index[tabId] = _history[tabId]!.length - 1;
    }
  }

  /// Whether there is a previous entry in the local history for [tabId].
  bool canGoBackLocal(String tabId) => (_index[tabId] ?? -1) > 0;

  /// Whether there is a next entry in the local history for [tabId].
  bool canGoForwardLocal(String tabId) {
    if (!_history.containsKey(tabId)) return false;
    final idx = _index[tabId] ?? -1;
    return idx < (_history[tabId]!.length - 1);
  }

  /// Moves the index back and returns the previous URL, or null if at start.
  String? navigateBack(String tabId) {
    if (!canGoBackLocal(tabId)) return null;
    final idx = _index[tabId]!;
    _index[tabId] = idx - 1;
    return _history[tabId]![idx - 1];
  }

  /// Moves the index forward and returns the next URL, or null if at end.
  String? navigateForward(String tabId) {
    if (!canGoForwardLocal(tabId)) return null;
    final idx = _index[tabId]!;
    _index[tabId] = idx + 1;
    return _history[tabId]![idx + 1];
  }

  /// Resets the index for [tabId] (used when navigating back to empty page).
  void resetIndex(String tabId) {
    _index[tabId] = -1;
  }
}
