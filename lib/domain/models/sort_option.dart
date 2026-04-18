import 'package:pigallery2_android/data/storage/models/sort_option.dart';

class SortOption {
  final SortOrder order;
  final SortType type;
  final bool onlyThisFolder;

  SortOption({required this.order, required this.type, required this.onlyThisFolder});

  SortOption.initial() : this(order: SortOrder.desc, type: SortType.date, onlyThisFolder: false);

  SortOption copyWith({
    SortOrder? order,
    SortType? type,
    bool? onlyThisFolder,
  }) => SortOption(
    order: order ?? this.order,
    type: type ?? this.type,
    onlyThisFolder: onlyThisFolder ?? this.onlyThisFolder,
  );
}
