import 'dart:async';
import 'dart:collection';

import 'package:media_kit/media_kit.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
    final entry = _entries[key];
    if (entry != null) {
      return entry.value;
    } else {
      return null;
    }
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
  }
}

class VideoModelControllerState {
  late final VideoControllerCache<int, VideoController> _cache;
  int? _currentItemId;

  VideoModelControllerState() {
    _cache = VideoControllerCache(
      onRemove: _onRemove,
      maximumSize: 3,
    );
  }

  VideoController? get videoController => _currentItemId?.let((it) => _cache[it]);

  void _onRemove(VideoController controller) {
    controller.player.dispose();
    if (_cache.length == 0) {
      _currentItemId = null;
    }
  }

  void addController(int id, VideoController controller) {
    _cache[id] = controller;
    if (_cache.length == 1) {
      setCurrentItemId(id);
    }
  }

  VideoController? getController(int id) {
    return _cache[id];
  }

  VideoController? getCurrentController() {
    return _currentItemId?.let((it) => getController(it));
  }

  /// Unmutes the video player for the [models.Media] item with the given [id].
  /// Mutes all other video players.
  void setCurrentItemId(int? id) {
    _currentItemId?.let((it) => getController(it)?.player.setVolume(0));
    id?.let((it) => getController(it))?.player.setVolume(100);
    _currentItemId = id;
    if (id == null) {
      _cache.removeLru();
    } else {
      _cache.promoteEntry(id);
    }
  }
}

/// Keeps track of how many widgets are referencing a video item.
/// Required to stop playback of videos when they are not visible anymore.
class VideoModelRefs {
  late final VideoModelControllerState _state;

  VideoModelRefs(VideoModelControllerState state) : _state = state;

  /// Maps [models.Media.id]s to how many Widgets referencing their video are currently mounted.
  final Map<int, int> _refs = {};

  /// Decrease the [_refs] counter by 1 for the given id.
  /// Pauses the playback if no other widget references the id.
  void unregisterMountedWidget(int id) {
    int? currentRefs = _refs[id];
    if (currentRefs != null) {
      if (currentRefs <= 1) {
        _refs.remove(id);
        _state.getController(id)?.player.pause();
      } else {
        _refs[id] = currentRefs - 1;
      }
    }
  }

  /// Increase the [_refs] counter by 1 for the given id.
  /// Starts playback if this is the first widget registered.
  void registerMountedWidget(int id) {
    _refs.update(id, (value) => value += 1, ifAbsent: () => 1);
    if (_refs[id] == 1) {
      _state.getController(id)?.player.play();
    }
  }
}

class VideoModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  late final VideoModelControllerState _state;

  late final VideoModelRefs _refs;

  VideoModel() {
    _state = VideoModelControllerState();
    _refs = VideoModelRefs(_state);
  }

  double _videoScale = 1.0;

  /// The [VideoController] of the Widget with > 50% visibility.
  /// null if the current item is not a video.
  VideoController? get videoController => _state.getCurrentController();

  /// Unregister a Widget that displayed the [models.Media] video with the given [id].
  /// Required to stop the playback after the video is no longer visible.
  void unregisterMountedWidget(int id) {
    _refs.unregisterMountedWidget(id);
  }

  /// Register a Widget that wants to display the [models.Media] video with the given [id].
  void registerMountedWidget(int id) {
    _refs.registerMountedWidget(id);
  }

  /// Creates a [VideoController] for the given [url] and [headers].
  /// Returns a [Stream] that emits once the controller is ready to display the first frame.
  Stream<VideoController> initializeVideoController(String url, Map<String, String> headers, int id) {
    VideoController? existingController = _state.getController(id);
    if (existingController != null) {
      return existingController.waitUntilFirstFrameRendered.asStream().map((event) => existingController);
    }

    Player player = Player(configuration: const PlayerConfiguration(bufferSize: 128 * 1024 * 1024));
    player.setVolume(0);
    VideoController newController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        vo: "mediacodec_embed",
        hwdec: "mediacodec",
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );

    Media playable = Media(url, httpHeaders: headers);
    player.setPlaylistMode(PlaylistMode.loop);
    player.open(playable);

    _state.addController(id, newController);
    return newController.waitUntilFirstFrameRendered.asStream().map((event) => newController);
  }

  /// Invoked when the page changes (a new view has > 50% visibility)
  @override
  set currentItem(FullscreenItem item) {
    /// Remove controller if new item is not a video.
    if (!item.item.isVideo) {
      _state.setCurrentItemId(null);
    } else {
      _state.setCurrentItemId(item.item.id);
    }
    _videoScale = 1.0;
    notifyListeners();
  }

  set videoScale(double val) {
    _videoScale = val;
    notifyListeners();
  }

  double get videoScale => _videoScale;
}
