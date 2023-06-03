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
  double creationDate; // in milliseconds (with sub-milliseconds precision)
  MediaMetadata({required this.size, required this.fileSize, required this.creationDate});
  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      size: json.containsKey('size')
          ? MediaDimension.fromJson(json['size'])
          : MediaDimension.fromList(json['d']),
      fileSize: json['fileSize'] ?? json['s'],
      creationDate: numberToDouble(json['creationDate'] ?? json['t']),
    );
  }
}

/// Convert int to double - if [value] is of type [int].
/// Required since there's no implicit conversion from int to double.
double numberToDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else {
    throw FormatException("type ${value.runtimeType} is not a subtype of type 'double'");
  }
}
