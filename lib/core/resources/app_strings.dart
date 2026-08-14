import 'package:browser_app/core/enum/connect_network/connect_network.dart'
    show DisconnectType;

class AppStrings {
  static const String titleMessage = 'Message';
  static const String confirmText = 'Confirm';
  static const String cancelText = 'Cancel';
  static const String savedPages = 'Saved pages';
  static const String bookmarks = 'Bookmarks';
  static const String readingList = 'Reading List';
  static const String saveBookmark = 'Save bookmark';
  static const String removeBookmark = 'Remove bookmark';
  static const String addToReadingList = 'Add to Reading List';
  static const String searchSavedPages = 'Search saved pages';
  static const String noSavedPages = 'Nothing saved yet';
  static const String importBookmarks = 'Import HTML';
  static const String exportBookmarks = 'Export HTML';
  static const String editSavedPage = 'Edit saved page';
  static const String title = 'Title';
  static const String folder = 'Folder';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String markRead = 'Mark as read';
  static const String markUnread = 'Mark as unread';
  static const String incognitoSaveBlocked =
      'Saved pages are disabled in Incognito mode.';
  static const String importOrExport = 'Import or export';
  static const String allFolders = 'All folders';
  static const String alreadySaved = 'Already saved';
  static const String savedPagesExported = 'Saved pages exported.';
  static const String pageTools = 'Page tools';
  static const String findInPage = 'Find in page';
  static const String previousMatch = 'Previous match';
  static const String nextMatch = 'Next match';
  static const String desktopSite = 'Desktop site';
  static const String textZoom = 'Text zoom';
  static const String reset = 'Reset';
  static const String sharePage = 'Share page';
  static const String copyLink = 'Copy link';
  static const String openExternally = 'Open in another app';
  static const String linkCopied = 'Link copied.';

  static String getDisconnectMessage(DisconnectType type) {
    switch (type) {
      case DisconnectType.internet:
        return "No internet connection. Please check your network.";
      case DisconnectType.server:
        return "Cannot reach the server. Try again later.";
      case DisconnectType.session:
        return "Session expired. Please log in again.";
      case DisconnectType.socket:
        return "Lost real-time connection. Reconnecting...";
    }
  }
}
