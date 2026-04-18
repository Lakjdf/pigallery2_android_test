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
/// sorted by [Metadata.date]. Items with a non-positive date are treated as
/// epoch-0 (January 1970) rather than discarded, so a missing creation date
/// doesn't cause silent data loss in the timeline.
List<TimelineSection> groupByMonth(List<Media> media) {
  final sections = <TimelineSection>[];
  DateTime? currentMonth;
  List<Media>? currentItems;

  for (final item in media) {
    // `metadata.date` is seconds since epoch (see fullscreen_overlay.dart,
    // media_info_bottom_sheet.dart). The field's doc comment calls it ms but
    // the actual backend value is seconds.
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
