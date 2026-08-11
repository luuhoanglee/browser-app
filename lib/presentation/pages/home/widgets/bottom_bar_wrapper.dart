import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:browser_app/features/tabs/bloc/tab_bloc.dart';
import 'package:browser_app/features/tabs/bloc/tab_state.dart';
import 'package:browser_app/domain/entities/saved_page_entity.dart';
import 'package:browser_app/features/library/bloc/saved_page_bloc.dart';
import 'package:browser_app/features/library/bloc/saved_page_state.dart';
import 'bottom_bar.dart';

/// BlocBuilder wrapper that rebuilds [BottomBar] only when the active tab's
/// URL, title, loading state, tab count, or incognito mode changes.
class BottomBarWrapper extends StatelessWidget {
  final String activeTabId;
  final InAppWebViewController? controller;
  final VoidCallback onShowTabs;
  final VoidCallback onAddressBarTap;
  final VoidCallback onShowHistory;
  final VoidCallback onShowDownload;
  final VoidCallback onShowMedia;
  final VoidCallback onShowWarp;
  final VoidCallback onShowSavedPages;
  final VoidCallback onToggleBookmark;
  final bool isSearching;
  final bool isMediaSheetOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearch;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final Future<bool> Function() canGoBack;
  final Future<bool> Function() canGoForward;

  const BottomBarWrapper({
    super.key,
    required this.activeTabId,
    required this.controller,
    required this.onShowTabs,
    required this.onAddressBarTap,
    required this.onShowHistory,
    required this.onShowDownload,
    required this.onShowMedia,
    required this.onShowWarp,
    required this.onShowSavedPages,
    required this.onToggleBookmark,
    required this.isSearching,
    required this.isMediaSheetOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    required this.onBack,
    required this.onForward,
    required this.canGoBack,
    required this.canGoForward,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      buildWhen: (previous, current) {
        final prevActiveTab = previous.activeTab;
        final currActiveTab = current.activeTab;

        if (previous.isIncognitoMode != current.isIncognitoMode) return true;

        if (prevActiveTab?.id != activeTabId ||
            currActiveTab?.id != activeTabId) {
          final prevTab = previous.tabs.firstWhere(
            (t) => t.id == activeTabId,
            orElse: () => previous.activeTab!,
          );
          final currTab = current.tabs.firstWhere(
            (t) => t.id == activeTabId,
            orElse: () => current.activeTab!,
          );
          return prevTab.url != currTab.url ||
              prevTab.title != currTab.title ||
              prevTab.isLoading != currTab.isLoading ||
              previous.tabs.length != current.tabs.length;
        }

        return prevActiveTab?.url != currActiveTab?.url ||
            prevActiveTab?.title != currActiveTab?.title ||
            prevActiveTab?.isLoading != currActiveTab?.isLoading ||
            previous.tabs.length != current.tabs.length;
      },
      builder: (context, tabState) {
        final activeTab = tabState.tabs.firstWhere(
          (t) => t.id == activeTabId,
          orElse: () => tabState.activeTab!,
        );
        return BlocBuilder<SavedPageBloc, SavedPageState>(
          buildWhen: (previous, current) => previous.items != current.items,
          builder: (context, savedState) => BottomBar(
            activeTab: activeTab,
            tabState: tabState,
            controller: controller,
            onShowTabs: onShowTabs,
            onAddressBarTap: onAddressBarTap,
            onShowHistory: onShowHistory,
            onShowDownload: onShowDownload,
            onShowMedia: onShowMedia,
            onShowWarp: onShowWarp,
            onShowSavedPages: onShowSavedPages,
            onToggleBookmark: onToggleBookmark,
            isBookmarked: savedState.containsUrl(
              activeTab.url,
              SavedPageCollection.bookmarks,
            ),
            isSearching: isSearching,
            isMediaSheetOpen: isMediaSheetOpen,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearch: onSearch,
            onBack: onBack,
            onForward: onForward,
            canGoBack: canGoBack,
            canGoForward: canGoForward,
          ),
        );
      },
    );
  }
}
