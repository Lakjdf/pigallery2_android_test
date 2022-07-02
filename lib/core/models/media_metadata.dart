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
  int fileSize;
  int creationDate;
  MediaMetadata({required this.size, required this.fileSize, required this.creationDate});
  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      size: MediaDimension.fromJson(json['size']),
      fileSize: json['fileSize'],
      creationDate: json['creationDate'],
    );
  }
}
