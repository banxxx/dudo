import 'package:audio_service/audio_service.dart';
import 'package:dudo/core/tts/tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lock-screen controls drive the online queue callbacks',
      (tester) async {
    final handler = TtsAudioHandler(FlutterTts());
    var paused = 0;
    var resumed = 0;
    var next = 0;
    var previous = 0;

    handler.beginOnlinePlayback();
    handler.onOnlinePause = () async => paused++;
    handler.onOnlineResume = () async => resumed++;
    handler.onOnlineSkipToNext = () async => next++;
    handler.onOnlineSkipToPrevious = () async => previous++;

    await handler.pause();
    await handler.play();
    await handler.skipToNext();
    await handler.skipToPrevious();

    expect(paused, 1);
    expect(resumed, 1);
    expect(next, 1);
    expect(previous, 1);
  });

  testWidgets('the notification mirrors online pause and resume',
      (tester) async {
    final handler = TtsAudioHandler(FlutterTts());

    handler.beginOnlinePlayback();
    expect(handler.playbackState.value.playing, isTrue);
    expect(handler.playbackState.value.controls.first, MediaControl.pause);

    await handler.pause();
    expect(handler.playbackState.value.playing, isFalse);
    expect(handler.playbackState.value.controls.first, MediaControl.play);

    await handler.play();
    expect(handler.playbackState.value.playing, isTrue);

    // The in-app panel pauses the player directly; the handler has to be told
    // so the notification does not keep claiming it is playing.
    handler.setOnlinePlaying(false);
    expect(handler.playbackState.value.playing, isFalse);
    expect(handler.playbackState.value.controls.first, MediaControl.play);
  });

  testWidgets('stopping online playback releases the control callbacks',
      (tester) async {
    final handler = TtsAudioHandler(FlutterTts())
      ..beginOnlinePlayback()
      ..onOnlinePause = () async {}
      ..onOnlineResume = () async {};

    await handler.stop();

    expect(handler.onOnlinePause, isNull);
    expect(handler.onOnlineResume, isNull);
  });
}
