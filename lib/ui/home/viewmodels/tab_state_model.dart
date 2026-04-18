import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

enum TabEntry {
  home(0),
  albums(1),
  timeline(2),
  website(3);

  final int pos;

  const TabEntry(this.pos);

  factory TabEntry.fromPosition(int pos) {
    return TabEntry.values.firstWhere((type) => type.index == pos);
  }
}

class TabStateModel extends SafeChangeNotifier {
  double _scroll;

  TabStateModel({required int initialTab}) : _scroll = initialTab.toDouble();

  TabEntry get currentTab => TabEntry.fromPosition(_scroll.round());
  double get currentScroll => _scroll;

  void setTabScroll(double progress) {
    if (progress != _scroll) {
      _scroll = progress;
      notifyListeners();
    }
  }
}

/// Bridges [TabStateModel] to [SharedPrefsStorage]: reads the last-selected
/// tab on startup and writes back whenever the tab changes.
class TabStatePersistence {
  final TabStateModel _tabStateModel;
  final SharedPrefsStorage _storage;
  int _persistedTab;

  TabStatePersistence(this._tabStateModel, this._storage)
      : _persistedTab = _tabStateModel.currentTab.pos {
    _tabStateModel.addListener(_onTabChanged);
  }

  static int readInitialTab(SharedPrefsStorage storage) {
    final raw = storage.get(StorageKey.selectedTab);
    if (raw < 0 || raw >= TabEntry.values.length) return 0;
    return raw;
  }

  void dispose() {
    _tabStateModel.removeListener(_onTabChanged);
  }

  void _onTabChanged() {
    final tabPos = _tabStateModel.currentTab.pos;
    if (tabPos != _persistedTab) {
      _persistedTab = tabPos;
      _storage.set(StorageKey.selectedTab, tabPos);
    }
  }
}
