import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:browser_app/core/resources/app_info.dart';
import 'package:browser_app/core/extentions/translate_string.dart';

class AppTrackingTransparencyUtils {
  static void initPlugin() {
    AppTrackingTransparency.trackingAuthorizationStatus.then((status) async {
      // If the system can show an authorization request dialog
      if (status == TrackingStatus.notDetermined) {
        // Show a custom explainer dialog before the system dialog
        if (AppInfo.navigatorKey.currentContext != null) {
          await showCustomTrackingDialog(AppInfo.navigatorKey.currentContext!);
        }
        // Wait for dialog popping animation
        await Future.delayed(const Duration(milliseconds: 200));
        // Request system's tracking authorization dialog
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    });
  }

  static Future<void> showCustomTrackingDialog(BuildContext context) async =>
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Dear User'.tr),
          content: Text(
            'We care about your privacy and data security. We keep this app free by showing ads. '
                'Can we continue to use your data to tailor ads for you?\n\nYou can change your choice anytime in the app settings. '
                'Our partners will collect data and use a unique identifier on your device to show you ads.'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue'.tr),
            ),
          ],
        ),
      );
}