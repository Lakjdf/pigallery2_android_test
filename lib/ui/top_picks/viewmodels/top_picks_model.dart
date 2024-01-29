import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_helper.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class TopPicksModel extends SafeChangeNotifier {
  final ItemRepository _itemRepository;
  final SharedPrefsStorage _storage;
  late final StorageHelper _storageHelper;

  TopPicksModel(this._itemRepository, this._storage) {
    _storageHelper = StorageHelper(_storage);
    _currentServerUrl = _storageHelper.getSelectedServerUrl();
  }

  CancelableOperation? _currentRequest;
  bool _isLoading = false;
  Map<int, List<Media>> _content = {};
  int? _currentDaysLength;

  /// Reload content if a different server has been selected
  String? _currentServerUrl;

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

  void fetchTopPicks(int daysLength) {
    String? serverUrl = _storageHelper.getSelectedServerUrl();
    if (_currentDaysLength == daysLength && _currentServerUrl == serverUrl) return;
    _isLoading = true;
    _currentRequest?.cancel();
    _currentDaysLength = daysLength;
    if (_currentServerUrl == serverUrl) {
      notifyListeners();
    } else {
      _content = {};
    }
    _currentServerUrl = serverUrl;
    _currentRequest = CancelableOperation.fromFuture(_fetchTopPicks(daysLength)).then((value) {
      _isLoading = false;
      _content = _groupMedia(value?.media ?? []);
      notifyListeners();
    });
  }
}
