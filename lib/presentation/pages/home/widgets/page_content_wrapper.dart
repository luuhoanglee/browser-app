import 'package:flutter/material.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';

/// Wraps the page content (WebView / EmptyPage stack) inside an
/// [AnimatedContainer] so future padding animations are easy to add.
class PageContentWrapper extends StatelessWidget {
  final dynamic activeTab;
  final TabState tabState;
  final Widget Function(BuildContext, dynamic, TabState) buildPageContent;

  const PageContentWrapper({
    super.key,
    required this.activeTab,
    required this.tabState,
    required this.buildPageContent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.zero,
      child: buildPageContent(context, activeTab, tabState),
    );
  }
}
