import 'package:media_kit/media_kit.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_source.dart';

/// `media_kit` backed [AppVideoPlayer].
class MediaKitVideoPlayer implements AppVideoPlayer {
  final Player player;

  /// Setup that must complete before the first [open] (e.g. mpv properties that
  /// have to be applied before playback starts). Null when there is none.
  final Future<void>? _ready;

  MediaKitVideoPlayer(this.player, {Future<void>? ready}) : _ready = ready;

  @override
  Future<void> open(AppVideoSource source, {bool play = true}) async {
    final ready = _ready;
    if (ready != null) await ready;
    final Playable playable = await _toPlayable(source);
    await player.open(playable, play: play);
  }

  Future<Playable> _toPlayable(AppVideoSource source) async {
    switch (source) {
      case NetworkVideoSource(:final url, :final headers):
        return Media(url, httpHeaders: headers);
      case BytesVideoSource(:final bytes):
        return await Media.memory(bytes);
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> setVolume(double volume) => player.setVolume(volume);

  @override
  Future<void> dispose() => player.dispose();

  @override
  Duration get position => player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  Duration get buffer => player.state.buffer;

  @override
  bool get isPlaying => player.state.playing;

  @override
  bool get isBuffering => player.state.buffering;

  @override
  double? get aspectRatio => player.state.videoParams.aspect;

  @override
  Stream<Duration> get positionStream => player.stream.position;

  @override
  Stream<Duration> get durationStream => player.stream.duration;

  @override
  Stream<Duration> get bufferStream => player.stream.buffer;

  @override
  Stream<bool> get bufferingStream => player.stream.buffering;

  @override
  Stream<String> get errorStream => player.stream.error;
}
