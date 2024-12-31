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