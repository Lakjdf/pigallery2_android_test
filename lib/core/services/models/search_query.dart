sealed class SearchQuery {
  int type = 100; // only support 'any_text'

  SearchQuery();
}

class TextSearchQuery extends SearchQuery {
  String text;

  TextSearchQuery({required this.text});

  @override
  factory TextSearchQuery.fromJson(Map<String, dynamic> json) {
    return TextSearchQuery(
      text: json['text']
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };
}
