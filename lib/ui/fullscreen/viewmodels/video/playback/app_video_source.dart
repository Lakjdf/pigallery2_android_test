import 'dart:typed_data';

/// A package-agnostic description of something that can be played back.
///
/// Concrete [VideoPlayerFactory] implementations translate this into whatever
/// their underlying package understands.
sealed class AppVideoSource {
  const AppVideoSource();

  /// A video streamed from [url], sending [headers] with the request.
  const factory AppVideoSource.network(String url, {Map<String, String> headers}) = NetworkVideoSource;

  /// A video played from in-memory [bytes] (e.g. the clip extracted from a
  /// motion photo).
  const factory AppVideoSource.bytes(Uint8List bytes) = BytesVideoSource;
}

class NetworkVideoSource extends AppVideoSource {
  final String url;
  final Map<String, String> headers;

  const NetworkVideoSource(this.url, {this.headers = const {}});
}

class BytesVideoSource extends AppVideoSource {
  final Uint8List bytes;

  const BytesVideoSource(this.bytes);
}
