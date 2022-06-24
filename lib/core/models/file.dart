class File {
  String name;
  int id;
  File({
    required this.name,
    required this.id,
  });

  factory File.fromJson(Map<String, dynamic> json) {
    return File(name: json['name'], id: json['id']);
  }
}
