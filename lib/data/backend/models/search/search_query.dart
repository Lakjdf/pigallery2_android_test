sealed class SearchQuery {
  abstract int type;

  SearchQuery();
}

class TextSearchQuery extends SearchQuery {
  @override
  int type = 100;

  String text;

  TextSearchQuery({required this.text});

  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };

  TextSearchQuery.fromJson(Map<String, dynamic> json) : text = json["text"] ?? "";
}

class TopPicksQuery extends SearchQuery {
  @override
  int type = 60;
  int daysLength;

  TopPicksQuery({this.daysLength = 3});

  Map<String, dynamic> toJson() => {
        'type': type,
        'daysLength': daysLength,
        'frequency': 3, // every_year
      };
}
