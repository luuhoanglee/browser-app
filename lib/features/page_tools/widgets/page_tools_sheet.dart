import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_strings.dart';
import '../../../domain/entities/tab_entity.dart';
import '../bloc/page_tools_cubit.dart';

class PageToolsSheet extends StatefulWidget {
  final TabEntity tab;
  final InAppWebViewController controller;
  final ValueChanged<bool> onDesktopModeChanged;
  final ValueChanged<int> onTextZoomChanged;

  const PageToolsSheet({
    super.key,
    required this.tab,
    required this.controller,
    required this.onDesktopModeChanged,
    required this.onTextZoomChanged,
  });

  @override
  State<PageToolsSheet> createState() => _PageToolsSheetState();
}

class _PageToolsSheetState extends State<PageToolsSheet> {
  final TextEditingController _findController = TextEditingController();

  @override
  void dispose() {
    widget.controller.clearMatches();
    context.read<PageToolsCubit>().clearFindResult(widget.tab.id);
    _findController.dispose();
    super.dispose();
  }

  Future<void> _find(String value) async {
    if (value.trim().isEmpty) {
      await widget.controller.clearMatches();
      if (mounted)
        context.read<PageToolsCubit>().clearFindResult(widget.tab.id);
      return;
    }
    await widget.controller.findAllAsync(find: value.trim());
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.tab.url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.linkCopied)));
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(text: '${widget.tab.title}\n${widget.tab.url}'),
    );
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.tab.url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      AppLogger.warning('PageTools', 'Could not open URL externally');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.pageTools,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            BlocBuilder<PageToolsCubit, PageToolsState>(
              builder: (context, state) {
                final result = state.resultFor(widget.tab.id);
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _findController,
                        autofocus: false,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          labelText: AppStrings.findInPage,
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _find,
                        onSubmitted: _find,
                      ),
                    ),
                    Semantics(
                      label: AppStrings.previousMatch,
                      button: true,
                      child: IconButton(
                        tooltip: AppStrings.previousMatch,
                        onPressed: result.matchCount == 0
                            ? null
                            : () => widget.controller.findNext(forward: false),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                    ),
                    Text('${result.activeMatch}/${result.matchCount}'),
                    Semantics(
                      label: AppStrings.nextMatch,
                      button: true,
                      child: IconButton(
                        tooltip: AppStrings.nextMatch,
                        onPressed: result.matchCount == 0
                            ? null
                            : () => widget.controller.findNext(forward: true),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                  ],
                );
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.desktopSite),
              secondary: const Icon(Icons.desktop_windows_outlined),
              value: widget.tab.desktopMode,
              onChanged: widget.onDesktopModeChanged,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.text_fields),
              title: const Text(AppStrings.textZoom),
              subtitle: Slider(
                min: 50,
                max: 200,
                divisions: 6,
                label: '${widget.tab.textZoom}%',
                value: widget.tab.textZoom.toDouble().clamp(50, 200),
                onChanged: (value) => widget.onTextZoomChanged(value.round()),
              ),
              trailing: TextButton(
                onPressed: () => widget.onTextZoomChanged(100),
                child: const Text(AppStrings.reset),
              ),
            ),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.share_outlined,
                  label: AppStrings.sharePage,
                  onTap: _share,
                ),
                _ToolButton(
                  icon: Icons.link,
                  label: AppStrings.copyLink,
                  onTap: _copyLink,
                ),
                _ToolButton(
                  icon: Icons.open_in_new,
                  label: AppStrings.openExternally,
                  onTap: _openExternally,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.iconColor),
        label: Text(label),
      ),
    );
  }
}
