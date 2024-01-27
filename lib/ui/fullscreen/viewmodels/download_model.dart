import 'dart:async';

import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/paginated_fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:share_plus/share_plus.dart';

class DownloadModel extends SafeChangeNotifier implements PaginatedFullscreenModel {
  final MediaRepository _repository;
  Media _item;

  DownloadModel(this._repository, this._item);

  StreamSubscription<double>? _currentSubscription;

  bool downloading = false;
  double progress = 0;

  void _resetState() {
    progress = 0;
    downloading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentSubscription?.cancel();
    super.dispose();
  }

  @override
  set currentItem(Media item) {
    _currentSubscription?.cancel();
    progress = 0;
    downloading = false;
    _item = item;
  }

  Future<void> cancel() async {
    StreamSubscription<double>? subscription = _currentSubscription;
    if (subscription != null) {
      await subscription.cancel();
    }
    _resetState();
  }

  Future<void> _showShareDialog(String filePath) {
    return Share.shareXFiles([XFile(filePath)]).then((value) => _resetState());
  }

  Future<void> share() async {
    String? filePath = await _repository.getFilePath(_item);
    if (filePath != null) {
      _showShareDialog(filePath);
      return;
    }

    progress = 0;
    downloading = true;
    notifyListeners();

    StreamSubscription<double> stream = _repository.download(_item);
    _currentSubscription?.cancel();
    _currentSubscription = stream;
    stream.onData((data) async {
      progress = data;
      notifyListeners();
    });
    stream.onDone(() async {
      String? filePath = await _repository.getFilePath(_item);
      if (filePath != null) {
        _showShareDialog(filePath);
      }
    });
  }
}
