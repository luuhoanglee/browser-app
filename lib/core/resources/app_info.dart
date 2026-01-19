import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart' show GlobalKey, NavigatorState;

class AppInfo {
  static PackageInfo? package;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();
}