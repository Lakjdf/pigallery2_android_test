sealed class SearchQuery {
  abstract int type;

  SearchQuery();

  Map<String, dynamic> toJson();
}

abstract class TextSearchQuery extends SearchQuery {
  String text;

  TextSearchQuery({required this.text});

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };
}

class AnyTextSearchQuery extends TextSearchQuery {
  @override
  int type = 100;

  AnyTextSearchQuery({required super.text});
}

class DirectorySearchQuery extends TextSearchQuery {
  @override
  int type = 102;

  DirectorySearchQuery({required super.text});
}

class TopPicksQuery extends SearchQuery {
  @override
  int type = 60;
  int daysLength;

  TopPicksQuery({this.daysLength = 3});

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'daysLength': daysLength,
        'frequency': 3, // every_year
      };
}

class AndSearchQuery extends SearchQuery {
  @override
  int type = 1;
  List<SearchQuery> queries;

  AndSearchQuery(this.queries);

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'list': queries.map((e) => e.toJson()).toList(),
      };
}
