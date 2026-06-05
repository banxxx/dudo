import '../domain/reader_document.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_viewport_state.dart';

enum ReaderLoadStatus {
  idle,
  loading,
  ready,
  error,
}

class ReaderOverlayState {
  const ReaderOverlayState({
    this.controlsVisible = false,
    this.catalogVisible = false,
    this.settingsVisible = false,
    this.ttsVisible = false,
  });

  final bool controlsVisible;
  final bool catalogVisible;
  final bool settingsVisible;
  final bool ttsVisible;

  ReaderOverlayState hideAll() => const ReaderOverlayState();
}

class ReaderSessionState {
  const ReaderSessionState({
    required this.settings,
    required this.overlay,
    required this.loadStatus,
    this.document,
    this.location,
    this.viewport,
    this.error,
  });

  factory ReaderSessionState.initial(ReaderSettings settings) {
    return ReaderSessionState(
      settings: settings,
      overlay: const ReaderOverlayState(),
      loadStatus: ReaderLoadStatus.idle,
    );
  }

  final ReaderDocument? document;
  final ReaderLocation? location;
  final ReaderSettings settings;
  final ReaderViewportState? viewport;
  final ReaderOverlayState overlay;
  final ReaderLoadStatus loadStatus;
  final Object? error;

  ReaderSessionState copyWith({
    ReaderDocument? document,
    ReaderLocation? location,
    ReaderSettings? settings,
    ReaderViewportState? viewport,
    ReaderOverlayState? overlay,
    ReaderLoadStatus? loadStatus,
    Object? error,
  }) {
    return ReaderSessionState(
      document: document ?? this.document,
      location: location ?? this.location,
      settings: settings ?? this.settings,
      viewport: viewport ?? this.viewport,
      overlay: overlay ?? this.overlay,
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
    );
  }
}
