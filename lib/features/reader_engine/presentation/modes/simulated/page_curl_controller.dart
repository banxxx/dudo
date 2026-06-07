import 'package:flutter/foundation.dart';

import 'page_curl_gesture.dart';

enum PageCurlTurnType {
  nextPageOut,
  previousPageIn,
}

enum PageCurlMotionPhase {
  interactive,
  completion,
}

class PageCurlController extends ChangeNotifier {
  PageCurlGesture? _gesture;
  PageCurlTurnType? _turnType;
  PageCurlMotionPhase _phase = PageCurlMotionPhase.interactive;

  PageCurlGesture? get gesture => _gesture;
  PageCurlTurnType? get turnType => _turnType;
  PageCurlMotionPhase get phase => _phase;
  bool get isActive => _gesture != null && _turnType != null;

  void update({
    required PageCurlGesture? gesture,
    required PageCurlTurnType? turnType,
    PageCurlMotionPhase phase = PageCurlMotionPhase.interactive,
  }) {
    _gesture = gesture;
    _turnType = gesture == null ? null : turnType;
    _phase = gesture == null ? PageCurlMotionPhase.interactive : phase;
    notifyListeners();
  }

  void clear() {
    if (_gesture == null &&
        _turnType == null &&
        _phase == PageCurlMotionPhase.interactive) {
      return;
    }
    _gesture = null;
    _turnType = null;
    _phase = PageCurlMotionPhase.interactive;
    notifyListeners();
  }
}
