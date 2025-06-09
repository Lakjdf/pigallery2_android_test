import 'dart:math';

class BackendMediaDimension {
  int width;
  int height;

  BackendMediaDimension({required this.width, required this.height});

  factory BackendMediaDimension.fromJson(Map<String, dynamic> json) {
    return BackendMediaDimension(
      width: json['width'],
      height: json['height'],
    );
  }

  factory BackendMediaDimension.fromList(List<dynamic> list) {
    return BackendMediaDimension(
      width: max(1,list[0]),
      height: max(1, list[1]),
    );
  }
}

class BackendMediaMetadata {
  BackendMediaDimension size;
  int fileSize;
  double creationDate; // in milliseconds (with sub-milliseconds precision)
  BackendMediaMetadata({required this.size, required this.fileSize, required this.creationDate});
  factory BackendMediaMetadata.fromJson(Map<String, dynamic> json) {
    return BackendMediaMetadata(
      size: json.containsKey('size')
          ? BackendMediaDimension.fromJson(json['size'])
          : BackendMediaDimension.fromList(json['d']),
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
