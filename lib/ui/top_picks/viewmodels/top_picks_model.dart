import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class TopPicksModel extends SafeChangeNotifier {
  final ItemRepository _itemRepository;
  final SharedPrefsStorage _storage;
  late final StorageHelper _storageHelper;

  TopPicksModel(this._itemRepository, this._storage) {
    _storageHelper = StorageHelper(_storage);
    _currentServerUrl = null;
    _showTopPicks = _storage.get(StorageKey.showTopPicks);
    _daysLength = _storage.get(StorageKey.topPicksDaysLength);
  }

  late int _daysLength;
  late bool _showTopPicks;

  CancelableOperation? _currentRequest;
  bool _isLoading = false;
  Map<int, List<Media>> _content = {};

  /// Reload content if a different server has been selected
  String? _currentServerUrl;

  /// Whether the top picks have been retrieved for the current server and are empty.
  bool get isUpToDateAndEmpty => _content.isEmpty && _currentServerUrl != null && _currentServerUrl == _storageHelper.getSelectedServerUrl();

  bool get isLoading => _isLoading;

  Map<int, List<Media>> get content => _content;

  Future<Directory?> _fetchTopPicks(int daysLength) {
    return _itemRepository.getTopPicks(daysLength).onError((error, stackTrace) {
      _isLoading = false;
      _content = {};
      notifyListeners();
      return null;
    });
  }

  int _yearFromUnixTimestamp(double timestamp) {
    return (DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000)).year;
  }

  Map<int, List<Media>> _groupMedia(List<Media> media) {
    Map<int, List<Media>> mediaByYear = groupBy(media, (it) => _yearFromUnixTimestamp(it.metadata.date));
    mediaByYear.removeWhere((key, value) => key == DateTime.now().year);
    return mediaByYear;
  }

  void _fetch() {
    _isLoading = true;
    notifyListeners();
    _currentRequest = CancelableOperation.fromFuture(_fetchTopPicks(_daysLength)).then((value) {
      _isLoading = false;
      _content = _groupMedia(value?.media ?? []);
      notifyListeners();
    });
  }

  /// Inform about changes to [daysLength] and [showTopPicks].
  /// Only fetches from [ItemRepository] if
  /// - showTopPicks is true and
  /// - [daysLength] or the current server url have changed.
  void update(int daysLength, bool showTopPicks) {
    _showTopPicks = showTopPicks;
    String? serverUrl = _storageHelper.getSelectedServerUrl();
    if (_daysLength == daysLength && _currentServerUrl == serverUrl) {
      // nothing changed
      return;
    }
    if (!showTopPicks) return; // only fetch if top picks are visible
    _daysLength = daysLength;
    _currentServerUrl = serverUrl;

    _currentRequest?.cancel();
    if (serverUrl == null) {
      // no server configured
      _content = {};
      notifyListeners();
      return;
    }
    _fetch();
  }

  /// Refresh the state in case the serverUrl has changed.
  void refresh() {
    if (_showTopPicks) {
      update(_daysLength, _showTopPicks);
    } else {
      _content = {};
    }
  }
}
