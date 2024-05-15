import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';

abstract interface class PaginatedFullscreenModel {
  void close();
  set currentItem(FullscreenItem item);
}
