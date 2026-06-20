import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_source.dart';
import 'package:video_player/video_player.dart';

/// `video_player` (official Flutter plugin, ExoPlayer on Android) backed
/// [AppVideoPlayer].
///
/// [VideoPlayerController] needs the source at construction time, so the
/// underlying controller is created lazily in [open]. Calls that may arrive
/// before that (e.g. [setVolume]) are remembered and applied once initialized.
///
/// `video_player` exposes state through a single [ValueListenable] rather than
/// streams, so a listener fans the relevant values out onto the broadcast
/// streams the rest of the app expects.
class VpVideoPlayer implements AppVideoPlayer {
  final bool _loop;

  VideoPlayerController? _controller;
  File? _tempFile;

  /// Volume in the app's 0–100 range, remembered until the controller exists.
  double _pendingVolume;

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Last emitted values, to de-duplicate the value-listenable fan-out.
  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;
  Duration _lastBuffer = Duration.zero;
  bool _lastBuffering = false;
  String? _lastError;

  final Completer<void> _ready = Completer<void>();

  VpVideoPlayer({bool loop = false, double initialVolume = 0}) : _loop = loop, _pendingVolume = initialVolume;

  /// The underlying controller, or null before [open] / after [dispose].
  VideoPlayerController? get controller => _controller;

  /// Completes once the controller has loaded its first frame.
  Future<void> get ready => _ready.future;

  @override
  Future<void> open(AppVideoSource source, {bool play = true}) async {
    final controller = await _createController(source);
    _controller = controller;
    controller.addListener(_onValueChanged);
    await controller.initialize();
    await controller.setLooping(_loop);
    await controller.setVolume((_pendingVolume / 100).clamp(0.0, 1.0));
    if (play) await controller.play();
    if (!_ready.isCompleted) _ready.complete();
    _onValueChanged();
  }

  Future<VideoPlayerController> _createController(AppVideoSource source) async {
    // Mix audio with other players so two videos can play at once while swiping
    // between them (cross-fade). Without this each ExoPlayer takes exclusive
    // audio focus and starting one pauses the other, unlike media_kit.
    final options = VideoPlayerOptions(mixWithOthers: true);
    switch (source) {
      case NetworkVideoSource(:final url, :final headers):
        return VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: headers, videoPlayerOptions: options);
      case BytesVideoSource(:final bytes):
        // video_player has no in-memory source, so spill to a temp file.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/vp_motion_${DateTime.now().microsecondsSinceEpoch}.mp4');
        await file.writeAsBytes(bytes, flush: true);
        _tempFile = file;
        return VideoPlayerController.file(file, videoPlayerOptions: options);
    }
  }

  void _onValueChanged() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;

    if (value.position != _lastPosition) {
      _lastPosition = value.position;
      _positionController.add(value.position);
    }
    if (value.duration != _lastDuration) {
      _lastDuration = value.duration;
      _durationController.add(value.duration);
    }
    final buffer = _bufferedEnd(value);
    if (buffer != _lastBuffer) {
      _lastBuffer = buffer;
      _bufferController.add(buffer);
    }
    if (value.isBuffering != _lastBuffering) {
      _lastBuffering = value.isBuffering;
      _bufferingController.add(value.isBuffering);
    }
    if (value.hasError && value.errorDescription != _lastError) {
      _lastError = value.errorDescription;
      _errorController.add(value.errorDescription ?? 'Unknown playback error');
    }
  }

  /// How far the player has buffered: the end of the buffered range covering the
  /// current position, falling back to the furthest buffered point.
  Duration _bufferedEnd(VideoPlayerValue value) {
    if (value.buffered.isEmpty) return Duration.zero;
    for (final range in value.buffered) {
      if (range.start <= value.position && value.position <= range.end) return range.end;
    }
    return value.buffered.last.end;
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> seek(Duration position) async => _controller?.seekTo(position);

  @override
  Future<void> setVolume(double volume) async {
    _pendingVolume = volume;
    await _controller?.setVolume((volume / 100).clamp(0.0, 1.0));
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onValueChanged);
    await controller?.dispose();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _bufferingController.close();
    await _errorController.close();
    try {
      await _tempFile?.delete();
    } catch (_) {}
  }

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  Duration get buffer {
    final controller = _controller;
    return controller == null ? Duration.zero : _bufferedEnd(controller.value);
  }

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  bool get isBuffering => _controller?.value.isBuffering ?? false;

  @override
  double? get aspectRatio {
    final size = _controller?.value.size;
    if (size == null || size.width == 0 || size.height == 0) return null;
    return size.width / size.height;
  }

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<bool> get bufferingStream => _bufferingController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;
}
