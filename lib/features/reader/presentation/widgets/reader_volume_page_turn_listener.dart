import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReaderVolumePageTurnListener extends StatefulWidget {
  const ReaderVolumePageTurnListener({
    super.key,
    required this.enabled,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final Widget child;

  @override
  State<ReaderVolumePageTurnListener> createState() =>
      _ReaderVolumePageTurnListenerState();
}

class _ReaderVolumePageTurnListenerState
    extends State<ReaderVolumePageTurnListener> {
  static const EventChannel _eventChannel =
      EventChannel('dudo.reader/volume_page_turn');

  final FocusNode _focusNode = FocusNode(debugLabel: 'reader-volume-page-turn');
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription();
  }

  @override
  void didUpdateWidget(covariant ReaderVolumePageTurnListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncSubscription();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.audioVolumeUp) {
      widget.onPreviousPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.audioVolumeDown) {
      widget.onNextPage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _syncSubscription() {
    if (!widget.enabled) {
      unawaited(_subscription?.cancel());
      _subscription = null;
      return;
    }
    if (_subscription != null) return;
    _subscription = _eventChannel.receiveBroadcastStream().listen(
          _handlePlatformEvent,
          onError: (_) {},
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handlePlatformEvent(dynamic event) {
    if (!widget.enabled) return;
    switch (event) {
      case 'volumeUp':
        widget.onPreviousPage();
      case 'volumeDown':
        widget.onNextPage();
    }
  }
}
