import '../models/quick_access_site.dart';

class QuickAccessState {
  final List<QuickAccessSite> sites;
  final bool isLoaded;

  const QuickAccessState({
    this.sites = const [],
    this.isLoaded = false,
  });

  QuickAccessState copyWith({
    List<QuickAccessSite>? sites,
    bool? isLoaded,
  }) {
    return QuickAccessState(
      sites: sites ?? this.sites,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
