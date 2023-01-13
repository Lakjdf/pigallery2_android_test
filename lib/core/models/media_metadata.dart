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

  factory MediaDimension.fromList(List<dynamic> list) {
    return MediaDimension(
      width: list[0],
      height: list[1],
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
      size: json.containsKey('size')
          ? MediaDimension.fromJson(json['size'])
          : MediaDimension.fromList(json['d']),
      fileSize: json['fileSize'] ?? json['s'],
      creationDate: json['creationDate'] ?? json['t'],
    );
  }
}
