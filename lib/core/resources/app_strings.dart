

import 'package:browser_app/core/enum/connect_network/connect_network.dart' show DisconnectType;

class AppStrings {
  static String titleMessage = 'Message';
  static String confirmText = 'Confirm';
  static String cancelText = 'Cancel';

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