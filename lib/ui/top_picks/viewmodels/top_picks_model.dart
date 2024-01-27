import 'package:async/async.dart';
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
  List<Media> _content = [];
  int? _currentDaysLength;
  /// Reload content if a different server has been selected
  String? _currentServerUrl;

  bool get isLoading => _isLoading;

  List<Media> get content => _content;

  Future<Directory?> _fetchTopPicks(int daysLength) {
    return _itemRepository.getTopPicks(daysLength).onError((error, stackTrace) {
      _isLoading = false;
      _content = [];
      notifyListeners();
      return null;
    });
  }

  void fetchTopPicks(int daysLength) {
    String? serverUrl = _storageHelper.getSelectedServerUrl();
    if (_currentDaysLength == daysLength && _currentServerUrl == serverUrl) return;
    _isLoading = true;
    _currentRequest?.cancel();
    _currentDaysLength = daysLength;
    _currentServerUrl = serverUrl;
    notifyListeners();
    _currentRequest = CancelableOperation.fromFuture(_fetchTopPicks(daysLength)).then((value) {
      _isLoading = false;
      _content = value?.media ?? [];
      notifyListeners();
    });
  }
}
