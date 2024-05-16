import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:pigallery2_android/util/extensions.dart';

class _LinkedEntry<K, V> {
  _LinkedEntry(this.key, this.value);

  K key;
  V value;

  _LinkedEntry<K, V>? next;
  _LinkedEntry<K, V>? previous;
}

/// Keeps the current VideoController at the head.
/// Elements are ordered by the time they are inserted/updated (besides the head).
/// Includes a callback that is invoked when an item is evicted.
class VideoControllerCache<K, V> {
  final Map<K, _LinkedEntry<K, V>> _entries = HashMap<K, _LinkedEntry<K, V>>();
  final int _maximumSize;
  final void Function(V)? _onRemove;

  final Logger _logger = Logger("VideoControllerCache");

  VideoControllerCache({
    void Function(V)? onRemove,
    int maximumSize = 5,
  })  : _maximumSize = maximumSize,
        _onRemove = onRemove;

  _LinkedEntry<K, V>? _head;
  _LinkedEntry<K, V>? _tail;

  int get length => _entries.length;

  int get maximumSize => _maximumSize;

  /// Move the entry with the [key] to the MRU position, if it exists.
  void promoteEntry(K key) {
    _entries[key]?.let((it) => _promoteEntry(it));
  }

  /// Moves [entry] to the MRU position, shifting the linked list if necessary.
  void _promoteEntry(_LinkedEntry<K, V> entry) {
    // If this entry is already in the MRU position we are done.
    if (entry == _head) {
      return;
    }

    if (entry.previous != null) {
      // If already existed in the map, link previous to next.
      entry.previous!.next = entry.next;

      // If this was the tail element, assign a new tail.
      if (_tail == entry) {
        _tail = entry.previous;
      }
    }
    // If this entry is not the end of the list then link the next entry to the previous entry.
    if (entry.next != null) {
      entry.next!.previous = entry.previous;
    }

    // Replace head with this element.
    if (_head != null) {
      _head!.previous = entry;
    }
    entry.previous = null;
    entry.next = _head;
    _head = entry;

    // Add a tail if this is the first element.
    if (_tail == null) {
      assert(length == 1);
      _tail = _head;
    }
  }

  /// Removes the LRU position, shifting the linked list if necessary.
  /// Invokes onRemove callback.
  void removeLru() {
    if (_tail == null) return;
    _logger.log(Level.FINE, "evicting ${_tail?.key}");

    // Remove the tail from the internal map.
    final removedEntry = _entries.remove(_tail!.key);

    // Remove the tail element itself.
    _tail = _tail!.previous;
    _tail?.next = null;

    // If we removed the last element, clear the head too.
    if (_tail == null) {
      _head = null;
    }

    if (removedEntry != null) {
      _onRemove?.let((it) => it(removedEntry.value));
    }
  }

  /// Get the value for a [key] in the [Map].
  V? operator [](Object? key) {
    return _entries[key]?.value;
  }

  /// If [key] already exists, promotes it behind the MRU position & assigns
  /// [value].
  ///
  /// Otherwise, adds [key] and [value] behind the MRU position.  If [length]
  /// exceeds [maximumSize] while adding, removes the LRU position.
  ///
  /// Does not promote to MRU since MRU represents the current item.
  void operator []=(K key, V value) {
    final entry = _LinkedEntry<K, V>(key, value);
    final currentHead = _head;

    _promoteEntry(_entries.putIfAbsent(key, () => entry)..value = value);

    // Promote previous entry again. We want to insert the item behind the head.
    if (currentHead != null && currentHead.key != key) {
      _promoteEntry(currentHead);
    }

    // Remove the LRU item if the size would be exceeded by adding this item.
    if (length > maximumSize) {
      assert(length == maximumSize + 1);
      removeLru();
    }

    _logger.log(Level.FINE, "state after inserting/updating $key: $this");
  }

  @override
  String toString() {
    final keys = [];
    var cur = _head;
    while (cur != null) {
      keys.add(cur.key);
      cur = cur.next;
    }
    return "keys: $keys";
  }
}
