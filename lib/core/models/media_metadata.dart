class MediaDimension {
  int width;
  int height;

  MediaDimension({required this.width, required this.height});

  factory MediaDimension.fromJson(Map<String, dynamic> json) {
    return MediaDimension(
      width: json['width'],
      height: json['height'],
    );
  }
}

class MediaMetadata {
  MediaDimension size;
  MediaMetadata({required this.size});
  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      size: MediaDimension.fromJson(json['size']),
    );
  }
}
