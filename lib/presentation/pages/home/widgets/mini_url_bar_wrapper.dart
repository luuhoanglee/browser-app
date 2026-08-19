import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';
import 'mini_url_bar.dart';

/// BlocBuilder wrapper that rebuilds [MiniUrlBar] only when the active tab's
/// URL changes.
class MiniUrlBarWrapper extends StatelessWidget {
  final String activeTabId;
  final InAppWebViewController? controller;
  final VoidCallback onTap;

  const MiniUrlBarWrapper({
    super.key,
    required this.activeTabId,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevTab = previous.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => previous.activeTab!,
        );
        final currTab = current.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => current.activeTab!,
        );
        return prevTab.url != currTab.url;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );
        return MiniUrlBar(
          activeTab: activeTab,
          controller: controller,
          onTap: onTap,
        );
      },
    );
  }
}
