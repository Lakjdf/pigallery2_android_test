import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';

class TopPicksModel extends ChangeNotifier {
  final ApiService _api;

  TopPicksModel(this._api) {
    _currentServerUrl = _api.serverUrl;
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
    return _api.getTopPicks(daysLength).onError((error, stackTrace) {
      _isLoading = false;
      _content = [];
      notifyListeners();
      return null;
    });
  }

  void fetchTopPicks(int daysLength) {
    if (_currentDaysLength == daysLength && _currentServerUrl == _api.serverUrl) return;
    _isLoading = true;
    _currentRequest?.cancel();
    _currentDaysLength = daysLength;
    _currentServerUrl = _api.serverUrl;
    notifyListeners();
    _currentRequest = CancelableOperation.fromFuture(_fetchTopPicks(daysLength)).then((value) {
      _isLoading = false;
      _content = value?.media ?? [];
      notifyListeners();
    });
  }
}
