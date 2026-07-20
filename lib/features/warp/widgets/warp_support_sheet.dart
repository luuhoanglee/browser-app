import 'dart:io';

import 'package:browser_app/core/logger/analytics_event.dart';
import 'package:browser_app/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WarpSupportSheet extends StatelessWidget {
  const WarpSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppLogger.event(AnalyticsEvent.warpOpened);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const WarpSupportSheet(),
    );
  }

  Future<void> _openExternal(
    BuildContext context,
    Uri uri,
    String eventName,
  ) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    AppLogger.event(eventName, params: {AnalyticsParam.success: launched});

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open 1.1.1.1 right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openStore(BuildContext context) async {
    if (Platform.isAndroid) {
      final marketUri = Uri.parse(
        'market://details?id=com.cloudflare.onedotonedotonedotone',
      );
      final launched = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        AppLogger.event(
          AnalyticsEvent.warpStoreOpened,
          params: {AnalyticsParam.success: true},
        );
        return;
      }
      if (!context.mounted) return;
      await _openExternal(
        context,
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.cloudflare.onedotonedotonedotone',
        ),
        AnalyticsEvent.warpStoreOpened,
      );
      return;
    }

    await _openExternal(
      context,
      Uri.parse(
        'https://apps.apple.com/app/1-1-1-1-faster-internet/id1423538627',
      ),
      AnalyticsEvent.warpStoreOpened,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Warp support sheet',
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WARP / 1.1.1.1',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Use Cloudflare protection for this device',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'Open or install 1.1.1.1',
                child: FilledButton.icon(
                  onPressed: () => _openStore(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open or install 1.1.1.1'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openExternal(
                  context,
                  Uri.parse('https://one.one.one.one/'),
                  AnalyticsEvent.warpSiteOpened,
                ),
                icon: const Icon(Icons.language),
                label: const Text('Visit Cloudflare WARP'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If the app is not installed, Pardix opens the official store page.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
