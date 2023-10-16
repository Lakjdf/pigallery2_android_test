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
}

class TopPicksQuery extends SearchQuery {
  @override
  int type = 60;

  TopPicksQuery();

  Map<String, dynamic> toJson() => {
        'type': type,
        'daysLength': 3,
        'frequency': 3, // every_year
      };
}
