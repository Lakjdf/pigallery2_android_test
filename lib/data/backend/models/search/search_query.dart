import 'package:collection/collection.dart';

sealed class SearchQuery {
  abstract int type;
  String get title;

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
  @override
  String get title => super.text;

  AnyTextSearchQuery({required super.text});
}

class DirectorySearchQuery extends TextSearchQuery {
  @override
  int type = 102;
  @override
  String get title => super.text;

  DirectorySearchQuery({required super.text});
}

class TopPicksQuery extends SearchQuery {
  @override
  int type = 60;
  int daysLength;
  @override
  String get title => "";

  TopPicksQuery({this.daysLength = 3});

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'daysLength': daysLength,
        'frequency': 3, // every_year
      };
}

class RecentlyAddedQuery extends SearchQuery {
  @override
  int type = 60;
  int daysLength;
  @override
  String get title => "";

  RecentlyAddedQuery({this.daysLength = 3});

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'daysLength': daysLength,
    'frequency': 13, // years_ago
    'agoNumber': 0,
  };
}

class AndSearchQuery extends SearchQuery {
  @override
  int type = 1;
  List<SearchQuery> queries;
  @override
  String get title => queries.firstWhereOrNull((it) => it is AnyTextSearchQuery)?.title ?? "";

  AndSearchQuery(this.queries);

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'list': queries.map((e) => e.toJson()).toList(),
      };
}
