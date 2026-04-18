import 'package:pigallery2_android/domain/models/item.dart';

/// A contiguous run of media items that share the same calendar month.
class TimelineSection {
  /// First day of the month the section belongs to.
  final DateTime month;
  final List<Media> items;

  TimelineSection({required this.month, required this.items});
}

/// Groups [media] into contiguous monthly sections.
///
/// Preserves the input order — callers are expected to pass items already
/// sorted by [Metadata.date].
List<TimelineSection> groupByMonth(List<Media> media) {
  final sections = <TimelineSection>[];
  DateTime? currentMonth;
  List<Media>? currentItems;

  for (final item in media) {
    final date = DateTime.fromMillisecondsSinceEpoch(item.metadata.date.toInt() * 1000);
    final month = DateTime(date.year, date.month);
    if (currentMonth == null || month != currentMonth) {
      currentMonth = month;
      currentItems = <Media>[];
      sections.add(TimelineSection(month: month, items: currentItems));
    }
    currentItems!.add(item);
  }
  return sections;
}
