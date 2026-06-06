import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PageCurlRenderBox fades reflected page ink toward page color', () {
    const pageColor = Color(0xFFF7F0DF);

    final fadeColor = PageCurlRenderBox.backsideInkFadeColorFor(pageColor);

    expect(_channel(fadeColor.r), _channel(pageColor.r));
    expect(_channel(fadeColor.g), _channel(pageColor.g));
    expect(_channel(fadeColor.b), _channel(pageColor.b));
    expect(_channel(fadeColor.a), closeTo(71, 1));
  });
}

int _channel(double value) {
  return (value * 255).round().clamp(0, 255);
}
