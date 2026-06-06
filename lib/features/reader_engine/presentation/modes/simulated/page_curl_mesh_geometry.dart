import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'page_curl_controller.dart';
import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';

class PageCurlMeshGeometry {
  const PageCurlMeshGeometry({
    required this.turnType,
    required this.positions,
    required this.textureCoordinates,
    required this.indices,
    required this.turningPath,
    required this.unturnedPath,
    required this.edgePath,
    required this.foldPath,
    required this.unturnedRect,
    required this.progress,
  });

  factory PageCurlMeshGeometry.fromGesture({
    required PageCurlGesture gesture,
    required PageCurlTurnType turnType,
    required Size pageSize,
    required Size imageSize,
    required PageCurlQuality quality,
  }) {
    final progress = gesture.progress.clamp(0.001, 1.0).toDouble();
    return switch (turnType) {
      PageCurlTurnType.nextPageOut => _buildNextPageOut(
          gesture: gesture,
          pageSize: pageSize,
          imageSize: imageSize,
          quality: quality,
          progress: progress,
        ),
      PageCurlTurnType.previousPageIn => _buildPreviousPageIn(
          gesture: gesture,
          pageSize: pageSize,
          imageSize: imageSize,
          quality: quality,
          progress: progress,
        ),
    };
  }

  final PageCurlTurnType turnType;
  final List<Offset> positions;
  final List<Offset> textureCoordinates;
  final List<int> indices;
  final Path turningPath;
  final Path unturnedPath;
  final Path edgePath;
  final Path foldPath;
  final Rect unturnedRect;
  final double progress;

  static const int _rowSegments = 8;

  static PageCurlMeshGeometry _buildNextPageOut({
    required PageCurlGesture gesture,
    required Size pageSize,
    required Size imageSize,
    required PageCurlQuality quality,
    required double progress,
  }) {
    final width = pageSize.width;
    final height = pageSize.height;
    final stripCount = math.max(8, quality.stripCount);
    const rowCount = _rowSegments;
    final revealWidth = math.max(1.0, width * progress);
    final foldX = width - revealWidth;
    final anchorBias = _anchorBias(gesture.anchor);
    final dragBias = ((gesture.current.dy / math.max(1.0, height)) - 0.5)
        .clamp(-0.5, 0.5)
        .toDouble();
    final positions = <Offset>[];
    final textures = <Offset>[];
    final indices = <int>[];

    for (var column = 0; column <= stripCount; column++) {
      final t = column / stripCount;
      final sourceX = foldX + revealWidth * t;
      final wave = math.sin(t * math.pi);
      final curlDepth = revealWidth * 0.14 * (0.35 + progress * 0.65);
      for (var row = 0; row <= rowCount; row++) {
        final v = row / rowCount;
        final sourceY = height * v;
        final verticalBow = math.sin(v * math.pi);
        final edgeWeight = t * t;
        final edgeBow = edgeWeight *
            verticalBow *
            revealWidth *
            0.095 *
            (0.45 + progress * 0.55);
        final x = sourceX - wave * curlDepth - edgeBow;
        final yWarp = wave * height * 0.032 * (anchorBias + dragBias);
        final topBottomInset = wave *
            height *
            0.018 *
            progress *
            math.cos((v - 0.5) * math.pi).abs();
        final y = sourceY + yWarp + (v - 0.5) * topBottomInset;
        positions.add(Offset(x, y));
        textures.add(_texturePoint(sourceX, sourceY, pageSize, imageSize));
      }
    }
    _addGridIndices(indices, stripCount, rowCount);

    final turningPath = _outlinePath(
      positions: positions,
      columnCount: stripCount,
      rowCount: rowCount,
    );
    final edgePath = _columnPath(
      positions: positions,
      column: stripCount,
      rowCount: rowCount,
    );
    final foldPath = _columnPath(
      positions: positions,
      column: 0,
      rowCount: rowCount,
    );
    final unturnedPath = _unturnedPathFromFold(
      foldPath: foldPath,
      pageSize: pageSize,
    );

    return PageCurlMeshGeometry(
      turnType: PageCurlTurnType.nextPageOut,
      positions: positions,
      textureCoordinates: textures,
      indices: indices,
      turningPath: turningPath,
      unturnedPath: unturnedPath,
      edgePath: edgePath,
      foldPath: foldPath,
      unturnedRect: Rect.fromLTWH(0, 0, math.max(0, foldX + 1), height),
      progress: progress,
    );
  }

  static PageCurlMeshGeometry _buildPreviousPageIn({
    required PageCurlGesture gesture,
    required Size pageSize,
    required Size imageSize,
    required PageCurlQuality quality,
    required double progress,
  }) {
    final width = pageSize.width;
    final height = pageSize.height;
    final stripCount = math.max(8, quality.stripCount);
    const rowCount = _rowSegments;
    final visibleWidth = math.max(1.0, width * progress);
    final anchorBias = _anchorBias(PageCurlAnchor.middle);
    final dragBias = ((gesture.current.dy / math.max(1.0, height)) - 0.5)
        .clamp(-0.35, 0.35)
        .toDouble();
    final positions = <Offset>[];
    final textures = <Offset>[];
    final indices = <int>[];

    for (var column = 0; column <= stripCount; column++) {
      final t = column / stripCount;
      final sourceX = width - visibleWidth + visibleWidth * t;
      final wave = math.sin(t * math.pi);
      final curlDepth = visibleWidth * 0.12 * (0.35 + progress * 0.65);
      for (var row = 0; row <= rowCount; row++) {
        final v = row / rowCount;
        final sourceY = height * v;
        final verticalBow = math.sin(v * math.pi);
        final edgeWeight = t * t;
        final edgeBow = edgeWeight *
            verticalBow *
            visibleWidth *
            0.08 *
            (0.45 + progress * 0.55);
        final x = visibleWidth * t + wave * curlDepth + edgeBow;
        final yWarp = wave * height * 0.018 * (anchorBias + dragBias);
        final topBottomInset = wave *
            height *
            0.014 *
            progress *
            math.cos((v - 0.5) * math.pi).abs();
        final y = sourceY + yWarp + (v - 0.5) * topBottomInset;
        positions.add(Offset(x, y));
        textures.add(_texturePoint(sourceX, sourceY, pageSize, imageSize));
      }
    }
    _addGridIndices(indices, stripCount, rowCount);

    final turningPath = _outlinePath(
      positions: positions,
      columnCount: stripCount,
      rowCount: rowCount,
    );
    final edgePath = _columnPath(
      positions: positions,
      column: stripCount,
      rowCount: rowCount,
    );
    final foldPath = _columnPath(
      positions: positions,
      column: stripCount,
      rowCount: rowCount,
    );

    return PageCurlMeshGeometry(
      turnType: PageCurlTurnType.previousPageIn,
      positions: positions,
      textureCoordinates: textures,
      indices: indices,
      turningPath: turningPath,
      unturnedPath: Path(),
      edgePath: edgePath,
      foldPath: foldPath,
      unturnedRect: Rect.zero,
      progress: progress,
    );
  }

  static double _anchorBias(PageCurlAnchor anchor) {
    return switch (anchor) {
      PageCurlAnchor.top => -0.45,
      PageCurlAnchor.middle => 0,
      PageCurlAnchor.bottom => 0.45,
    };
  }

  static Offset _texturePoint(
    double x,
    double y,
    Size pageSize,
    Size imageSize,
  ) {
    return Offset(
      x / math.max(1.0, pageSize.width) * imageSize.width,
      y / math.max(1.0, pageSize.height) * imageSize.height,
    );
  }

  static void _addGridIndices(
    List<int> indices,
    int columnCount,
    int rowCount,
  ) {
    final rowStride = rowCount + 1;
    for (var column = 0; column < columnCount; column++) {
      for (var row = 0; row < rowCount; row++) {
        final topLeft = column * rowStride + row;
        final bottomLeft = topLeft + 1;
        final topRight = topLeft + rowStride;
        final bottomRight = topRight + 1;
        indices
          ..addAll([topLeft, bottomLeft, topRight])
          ..addAll([topRight, bottomLeft, bottomRight]);
      }
    }
  }

  static Path _outlinePath({
    required List<Offset> positions,
    required int columnCount,
    required int rowCount,
  }) {
    final path = Path();
    if (positions.isEmpty) return path;
    final rowStride = rowCount + 1;
    path.moveTo(positions.first.dx, positions.first.dy);
    for (var column = 1; column <= columnCount; column++) {
      final point = positions[column * rowStride];
      path.lineTo(point.dx, point.dy);
    }
    for (var row = 1; row <= rowCount; row++) {
      final point = positions[columnCount * rowStride + row];
      path.lineTo(point.dx, point.dy);
    }
    for (var column = columnCount - 1; column >= 0; column--) {
      final point = positions[column * rowStride + rowCount];
      path.lineTo(point.dx, point.dy);
    }
    for (var row = rowCount - 1; row >= 0; row--) {
      final point = positions[row];
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path _columnPath({
    required List<Offset> positions,
    required int column,
    required int rowCount,
  }) {
    final rowStride = rowCount + 1;
    final start = positions[column * rowStride];
    final path = Path()..moveTo(start.dx, start.dy);
    for (var row = 1; row <= rowCount; row++) {
      final point = positions[column * rowStride + row];
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  static Path _unturnedPathFromFold({
    required Path foldPath,
    required Size pageSize,
  }) {
    final bounds = foldPath.getBounds();
    if (bounds.isEmpty) {
      return Path()..addRect(Offset.zero & pageSize);
    }
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(bounds.left, 0)
      ..addPath(foldPath, Offset.zero)
      ..lineTo(0, pageSize.height)
      ..close();
    return path;
  }
}
