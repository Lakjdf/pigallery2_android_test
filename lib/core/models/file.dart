import 'dart:math' as math;

class File {
  String name;
  int id;
  File({
    required this.name,
    required int? id,
  }) : id = id ?? math.Random().nextInt(4294967296); // create own id if not existing

  factory File.fromJson(Map<String, dynamic> json) {
    return File(name: json['name'], id: json['id']);
  }
}
