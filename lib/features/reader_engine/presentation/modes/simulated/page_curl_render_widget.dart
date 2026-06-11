import 'package:flutter/material.dart';

import 'page_curl_controller.dart';
import 'page_curl_quality.dart';
import 'page_curl_render_box.dart';
import 'page_curl_snapshot.dart';

class PageCurlRenderWidget extends LeafRenderObjectWidget {
  const PageCurlRenderWidget({
    super.key,
    required this.controller,
    required this.snapshots,
    required this.pageColor,
    required this.quality,
    this.backPageAppearance = const PageCurlBackPageAppearance(),
  });

  final PageCurlController controller;
  final PageCurlSnapshotPair? snapshots;
  final Color pageColor;
  final PageCurlQuality quality;
  final PageCurlBackPageAppearance backPageAppearance;

  @override
  PageCurlRenderBox createRenderObject(BuildContext context) {
    return PageCurlRenderBox(
      controller: controller,
      snapshots: snapshots,
      pageColor: pageColor,
      quality: quality,
      backPageAppearance: backPageAppearance,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    PageCurlRenderBox renderObject,
  ) {
    renderObject
      ..controller = controller
      ..snapshots = snapshots
      ..pageColor = pageColor
      ..quality = quality
      ..backPageAppearance = backPageAppearance;
  }
}
