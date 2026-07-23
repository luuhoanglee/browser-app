import 'package:flutter/material.dart';

/// Small floating button overlaid on a split-view pane that toggles whether the
/// pane plays sound (issue #20).
///
/// Both split panes keep rendering video; only the pane whose button shows the
/// "volume on" state is audible, so at most one pane produces sound at a time.
class SplitAudioToggle extends StatelessWidget {
  final bool muted;
  final VoidCallback onToggle;

  const SplitAudioToggle({
    super.key,
    required this.muted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final label = muted ? 'Bật tiếng pane này' : 'Tắt tiếng pane này';
    return Semantics(
      button: true,
      toggled: !muted,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 20,
                color: muted ? Colors.white70 : Colors.lightBlueAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
