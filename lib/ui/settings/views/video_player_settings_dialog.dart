import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/video_player_backend.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:provider/provider.dart';

/// Dialog letting the user pick the video playback engine and tune the
/// media_kit-only low-latency cache. Applies to newly opened videos.
class VideoPlayerSettingsDialog extends StatelessWidget {
  const VideoPlayerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const VideoPlayerSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text("Video Player"),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Consumer<GlobalSettingsModel>(
            builder: (context, model, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<VideoPlayerBackend>(
                  groupValue: model.videoPlayerBackend,
                  onChanged: (value) {
                    if (value != null) model.videoPlayerBackend = value;
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final backend in VideoPlayerBackend.values)
                        RadioListTile<VideoPlayerBackend>(
                          value: backend,
                          title: Text(backend.displayName),
                          subtitle: Text(backend.description),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Low-latency cache [Default enabled]"),
                  subtitle: const Text(
                    "Disables libmpv read-ahead caching to keep streaming latency and memory low. media_kit only.",
                  ),
                  secondary: Icon(Icons.speed, color: theme.colorScheme.onSurfaceVariant),
                  value: model.mediaKitLowLatencyCache,
                  onChanged: model.videoPlayerBackend.isMediaKit
                      ? (value) => model.mediaKitLowLatencyCache = value
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Done"),
        ),
      ],
    );
  }
}
