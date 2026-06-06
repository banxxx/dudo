import 'package:flutter/foundation.dart';

import 'page_curl_gesture.dart';

enum PageCurlTurnType {
  nextPageOut,
  previousPageIn,
}

class PageCurlController extends ChangeNotifier {
  PageCurlGesture? _gesture;
  PageCurlTurnType? _turnType;

  PageCurlGesture? get gesture => _gesture;
  PageCurlTurnType? get turnType => _turnType;
  bool get isActive => _gesture != null && _turnType != null;

  void update({
    required PageCurlGesture? gesture,
    required PageCurlTurnType? turnType,
  }) {
    _gesture = gesture;
    _turnType = gesture == null ? null : turnType;
    notifyListeners();
  }

  void clear() {
    if (_gesture == null && _turnType == null) return;
    _gesture = null;
    _turnType = null;
    notifyListeners();
  }
}
