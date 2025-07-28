import 'package:media_kit_video/media_kit_video.dart';

/// Alternatives for some Kotlin functions.
extension KotlinExt<T> on T {
  /// Calls the specified function [block] with this value as its argument and returns its result.
  R let<R>(R Function(T it) block) => block(this);

  /// Calls the specified function [block] with this value as its argument and returns this value.
  T also(void Function(T it) block) {
    block(this);
    return this;
  }
}

extension ListExtension<T> on List<T> {
  /// Same as [indexOf], but returns null instead of -1 if [it] could not be found.
  int? indexOfOrNull(T it) => indexOf(it).let((it) => it == -1 ? null : it);

  /// Add [it] if it is not part of the list. Returns whether [it] was added.
  bool addDistinct(T it) {
    if (!contains(it)) {
      add(it);
      return true;
    }
    return false;
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String? ifEmpty(String? defaultValue) => isNotEmpty ? this : defaultValue;

  /// Encode the uri to match the expected encoding of PiGallery2.
  String encodeUri() {
    return Uri.encodeFull(this)
        .replaceAll('#', '%23')
        .replaceAll('\$', '%24')
        .replaceAll('\'', '%27')
        .replaceAll(r'(', '%28')
        .replaceAll(')', '%29')
        .replaceAll('?', '%3F');
  }
}

extension DurationExtension on Duration {
  String format() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(inHours);
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60));

    final List<String> tokens = [];
    if (twoDigitHours != "00") {
      tokens.add(twoDigitHours);
    }
    tokens.add(twoDigitMinutes);
    tokens.add(twoDigitSeconds);

    return tokens.join(':');
  }
}

// https://stackoverflow.com/a/76902150
extension FileSizeExtensions on num {
  /// method returns a human readable string representing a file size
  /// size can be passed as number or as string
  /// the optional parameter 'round' specifies the number of numbers after comma/point (default is 2)
  /// the optional boolean parameter 'useBase1024' specifies if we should count in 1024's (true) or 1000's (false). e.g. 1KB = 1024B (default is true)
  String toHumanReadableFileSize({int round = 2, bool useBase1024 = false}) {
    const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

    num divider = useBase1024 ? 1024 : 1000;

    num size = this;
    num runningDivider = divider;
    num runningPreviousDivider = 0;
    int affix = 0;

    while (size >= runningDivider && affix < affixes.length - 1) {
      runningPreviousDivider = runningDivider;
      runningDivider *= divider;
      affix++;
    }

    String result = (runningPreviousDivider == 0 ? size : size / runningPreviousDivider).toStringAsFixed(round);

    //Check if the result ends with .00000 (depending on how many decimals) and remove it if found.
    if (result.endsWith("0" * round)) result = result.substring(0, result.length - round - 1);

    return "$result ${affixes[affix]}";
  }
}

extension VideoControllerExtension on VideoController {
  /// Whether the [VideoController] has been initialized.
  bool get isInitialized => player.platform?.videoControllerCompleter.isCompleted ?? false;
}
