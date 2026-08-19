import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';

/// BlocBuilder wrapper that renders a thin loading progress bar for the active
/// tab. Rebuilds only when loading state or progress changes significantly.
class ProgressBarWrapper extends StatelessWidget {
  final String activeTabId;

  const ProgressBarWrapper({super.key, required this.activeTabId});

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

        if (prevTab.isLoading != currTab.isLoading) return true;

        if (currTab.isLoading) {
          final delta =
              (currTab.loadProgress - prevTab.loadProgress).abs();
          return delta >= 10 ||
              currTab.loadProgress == 100 ||
              currTab.loadProgress == 0;
        }

        return false;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );

        if (!activeTab.isLoading) return const SizedBox.shrink();

        final isIncognito = activeTab.isIncognito;

        return TweenAnimationBuilder<double>(
          key: ValueKey(activeTab.loadProgress),
          tween: Tween(begin: 0, end: activeTab.loadProgress / 100),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, _) {
            return SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isIncognito ? Colors.white70 : const Color(0xFF2196F3),
                ),
                minHeight: 2,
              ),
            );
          },
        );
      },
    );
  }
}
