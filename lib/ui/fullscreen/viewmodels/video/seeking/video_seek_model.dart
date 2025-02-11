import 'dart:ui';

import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_position.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_preview_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/util/extensions.dart';

/// Controls the seeking of videos when the user interacts with the seek bar.
class VideoSeekModel extends SafeChangeNotifier {
  VideoSeekPosition? _ongoingSeekPosition;
  Offset? _ongoingDragPosition;
  VideoController? _videoController;
  final VideoSeekPreviewModel _previewModel;
  bool _seekInProgress = false;
  bool? _wasPlaying;

  /// The position of the ongoing seek.
  VideoSeekPosition? get ongoingSeekPosition => _ongoingSeekPosition;

  /// The current drag position of the user input.
  Offset? get ongoingDragPosition => _ongoingSeekPosition?.widgetPosition ?? _ongoingDragPosition;

  VideoSeekModel(
    VideoModel videoModel,
    this._previewModel,
  ) : _videoController = videoModel.videoControllerItem?.controller {
    videoModel.addListener(() {
      _videoController = videoModel.videoControllerItem?.controller;
    });
  }

  /// Call when the user is seeking by dragging the seek bar.
  void onSeek(Duration position, Offset widgetPosition) {
    // allow only ms precision
    Duration videoPosition = Duration(milliseconds: position.inMilliseconds);
    if (videoPosition != _ongoingSeekPosition?.videoPosition) {
      _previewModel.updateSeekPosition(videoPosition);
      _ongoingSeekPosition = VideoSeekPosition(videoPosition, widgetPosition);
      _ongoingDragPosition = widgetPosition;
      notifyListeners();
    }

    // seek directly when no preview is available
    if (!_previewModel.isAvailable) {
      _videoController?.player.pause();
      _seekToPosition(videoPosition);
    }
  }

  /// User input has ended.
  void onSeekEnd() {
    if (_previewModel.isAvailable) {
      _ongoingSeekPosition?.let((it) => _seekToPosition(it.videoPosition));
    }
    if (_wasPlaying == true) {
      _videoController?.player.play();
    }
    _wasPlaying = null;
    _ongoingDragPosition = null;
  }

  void _seekToPosition(Duration position) {
    // allow only one seek at a time
    if (_seekInProgress) return;
    _seekInProgress = true;
    _wasPlaying ??= (_videoController?.player.state.playing ?? true);
    _videoController?.player.seek(position).then((_) async => await _onSeekComplete(position));
  }

  Future<void> _onSeekComplete(Duration position) async {
    // wait until the videoController has updated its position. Might be off by > 10 ms
    await _videoController?.player.stream.position.firstWhere((it) {
      return (it.inMilliseconds / 100).round() == (position.inMilliseconds / 100).round();
    }).timeout(Duration(milliseconds: 100), onTimeout: () => Duration());

    Duration? pendingSeek = _ongoingSeekPosition?.videoPosition;
    if (pendingSeek != null && pendingSeek != position) {
      _videoController?.player.seek(pendingSeek).then((_) => _onSeekComplete(pendingSeek));
    } else {
      _ongoingSeekPosition = null;
      _seekInProgress = false;
      notifyListeners();
    }
  }
}
