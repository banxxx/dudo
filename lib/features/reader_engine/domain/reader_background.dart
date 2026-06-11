import 'dart:convert';

import 'package:flutter/widgets.dart';

enum ReaderBackgroundType {
  solid,
  builtinImage,
  customImage,
}

@immutable
class ReaderBackgroundPreference {
  const ReaderBackgroundPreference({
    required this.type,
    required this.id,
    this.assetPath,
    this.filePath,
    this.opacity = 0.14,
    this.alignment = Alignment.topRight,
    this.fit = BoxFit.cover,
    this.tintEnabled = true,
    this.grayscaleEnabled = false,
    this.blurRadius = 0,
  });

  static const solidId = 'solid';
  static const bambooId = 'bamboo_001';
  static const bambooCornerId = 'bamboo_002';
  static const bambooAssetPath = 'assets/images/reader_backgrounds/001.webp';
  static const bambooCornerAssetPath =
      'assets/images/reader_backgrounds/002.webp';
  static const maxBlurRadius = 18.0;

  factory ReaderBackgroundPreference.defaults() {
    return const ReaderBackgroundPreference(
      type: ReaderBackgroundType.solid,
      id: solidId,
      opacity: 0,
      alignment: Alignment.center,
      tintEnabled: false,
    );
  }

  factory ReaderBackgroundPreference.bamboo() {
    return const ReaderBackgroundPreference(
      type: ReaderBackgroundType.builtinImage,
      id: bambooId,
      assetPath: bambooAssetPath,
      opacity: 0.14,
      alignment: Alignment.topRight,
      fit: BoxFit.cover,
      tintEnabled: true,
    );
  }

  factory ReaderBackgroundPreference.bambooCorner() {
    return const ReaderBackgroundPreference(
      type: ReaderBackgroundType.builtinImage,
      id: bambooCornerId,
      assetPath: bambooCornerAssetPath,
      opacity: 0.14,
      alignment: Alignment.bottomRight,
      fit: BoxFit.cover,
      tintEnabled: true,
    );
  }

  factory ReaderBackgroundPreference.fromJson(Map<String, Object?> json) {
    final type = _typeFromString(json['type'] as String?);
    final id = json['id'] as String?;
    if (type == null || id == null || id.trim().isEmpty) {
      return ReaderBackgroundPreference.defaults();
    }

    final resolved = ReaderBackgroundCatalog.resolve(
      id: id,
      type: type,
      assetPath: json['assetPath'] as String?,
      filePath: json['filePath'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble(),
      alignment: _alignmentFromString(json['alignment'] as String?),
      fit: _fitFromString(json['fit'] as String?),
      tintEnabled: json['tintEnabled'] as bool?,
      grayscaleEnabled: json['grayscaleEnabled'] as bool?,
      blurRadius: (json['blurRadius'] as num?)?.toDouble(),
    );
    return resolved ?? ReaderBackgroundPreference.defaults();
  }

  factory ReaderBackgroundPreference.fromJsonString(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?>) {
        return ReaderBackgroundPreference.defaults();
      }
      return ReaderBackgroundPreference.fromJson(decoded);
    } catch (_) {
      return ReaderBackgroundPreference.defaults();
    }
  }

  final ReaderBackgroundType type;
  final String id;
  final String? assetPath;
  final String? filePath;
  final double opacity;
  final Alignment alignment;
  final BoxFit fit;
  final bool tintEnabled;
  final bool grayscaleEnabled;
  final double blurRadius;

  bool get hasImage =>
      type != ReaderBackgroundType.solid &&
      ((assetPath != null && assetPath!.isNotEmpty) ||
          (filePath != null && filePath!.isNotEmpty));

  Map<String, Object?> toJson() {
    return {
      'version': 1,
      'type': _typeToString(type),
      'id': id,
      if (assetPath != null) 'assetPath': assetPath,
      if (filePath != null) 'filePath': filePath,
      'opacity': opacity,
      'alignment': _alignmentToString(alignment),
      'fit': _fitToString(fit),
      'tintEnabled': tintEnabled,
      'grayscaleEnabled': grayscaleEnabled,
      'blurRadius': blurRadius,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  ReaderBackgroundPreference copyWith({
    ReaderBackgroundType? type,
    String? id,
    String? assetPath,
    String? filePath,
    double? opacity,
    Alignment? alignment,
    BoxFit? fit,
    bool? tintEnabled,
    bool? grayscaleEnabled,
    double? blurRadius,
  }) {
    return ReaderBackgroundPreference(
      type: type ?? this.type,
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      opacity: (opacity ?? this.opacity).clamp(0.0, 1.0).toDouble(),
      alignment: alignment ?? this.alignment,
      fit: fit ?? this.fit,
      tintEnabled: tintEnabled ?? this.tintEnabled,
      grayscaleEnabled: grayscaleEnabled ?? this.grayscaleEnabled,
      blurRadius:
          (blurRadius ?? this.blurRadius).clamp(0.0, maxBlurRadius).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderBackgroundPreference &&
        other.type == type &&
        other.id == id &&
        other.assetPath == assetPath &&
        other.filePath == filePath &&
        other.opacity == opacity &&
        other.alignment == alignment &&
        other.fit == fit &&
        other.tintEnabled == tintEnabled &&
        other.grayscaleEnabled == grayscaleEnabled &&
        other.blurRadius == blurRadius;
  }

  @override
  int get hashCode => Object.hash(
        type,
        id,
        assetPath,
        filePath,
        opacity,
        alignment,
        fit,
        tintEnabled,
        grayscaleEnabled,
        blurRadius,
      );
}

@immutable
class ReaderBackgroundPreset {
  const ReaderBackgroundPreset({
    required this.label,
    required this.preference,
  });

  final String label;
  final ReaderBackgroundPreference preference;
}

class ReaderBackgroundCatalog {
  ReaderBackgroundCatalog._();

  static final presets = <ReaderBackgroundPreset>[
    ReaderBackgroundPreset(
      label: '纯色',
      preference: ReaderBackgroundPreference.defaults(),
    ),
    ReaderBackgroundPreset(
      label: '竹影',
      preference: ReaderBackgroundPreference.bamboo(),
    ),
    ReaderBackgroundPreset(
      label: '竹韵',
      preference: ReaderBackgroundPreference.bambooCorner(),
    ),
  ];

  static ReaderBackgroundPreference? resolve({
    required String id,
    required ReaderBackgroundType type,
    String? assetPath,
    String? filePath,
    double? opacity,
    Alignment? alignment,
    BoxFit? fit,
    bool? tintEnabled,
    bool? grayscaleEnabled,
    double? blurRadius,
  }) {
    if (type == ReaderBackgroundType.solid ||
        id == ReaderBackgroundPreference.solidId) {
      return ReaderBackgroundPreference.defaults();
    }
    if (id == ReaderBackgroundPreference.bambooId) {
      return ReaderBackgroundPreference.bamboo().copyWith(
        opacity: opacity,
        alignment: alignment,
        fit: fit,
        tintEnabled: tintEnabled,
        grayscaleEnabled: grayscaleEnabled,
        blurRadius: blurRadius,
      );
    }
    if (id == ReaderBackgroundPreference.bambooCornerId) {
      return ReaderBackgroundPreference.bambooCorner().copyWith(
        opacity: opacity,
        alignment: alignment,
        fit: fit,
        tintEnabled: tintEnabled,
        grayscaleEnabled: grayscaleEnabled,
        blurRadius: blurRadius,
      );
    }
    if (type == ReaderBackgroundType.customImage &&
        filePath != null &&
        filePath.isNotEmpty) {
      return ReaderBackgroundPreference(
        type: type,
        id: id,
        filePath: filePath,
        assetPath: assetPath,
        opacity: opacity ?? 0.18,
        alignment: alignment ?? Alignment.center,
        fit: fit ?? BoxFit.cover,
        tintEnabled: tintEnabled ?? false,
        grayscaleEnabled: grayscaleEnabled ?? false,
        blurRadius: (blurRadius ?? 0)
            .clamp(0.0, ReaderBackgroundPreference.maxBlurRadius)
            .toDouble(),
      );
    }
    return null;
  }
}

String _typeToString(ReaderBackgroundType type) {
  return switch (type) {
    ReaderBackgroundType.solid => 'solid',
    ReaderBackgroundType.builtinImage => 'builtinImage',
    ReaderBackgroundType.customImage => 'customImage',
  };
}

ReaderBackgroundType? _typeFromString(String? value) {
  return switch (value) {
    'solid' => ReaderBackgroundType.solid,
    'builtinImage' => ReaderBackgroundType.builtinImage,
    'customImage' => ReaderBackgroundType.customImage,
    _ => null,
  };
}

String _alignmentToString(Alignment alignment) {
  if (alignment == Alignment.topLeft) return 'topLeft';
  if (alignment == Alignment.topCenter) return 'topCenter';
  if (alignment == Alignment.topRight) return 'topRight';
  if (alignment == Alignment.centerLeft) return 'centerLeft';
  if (alignment == Alignment.center) return 'center';
  if (alignment == Alignment.centerRight) return 'centerRight';
  if (alignment == Alignment.bottomLeft) return 'bottomLeft';
  if (alignment == Alignment.bottomCenter) return 'bottomCenter';
  if (alignment == Alignment.bottomRight) return 'bottomRight';
  return 'center';
}

Alignment? _alignmentFromString(String? value) {
  return switch (value) {
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'center' => Alignment.center,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => null,
  };
}

String _fitToString(BoxFit fit) {
  return switch (fit) {
    BoxFit.contain => 'contain',
    BoxFit.cover => 'cover',
    BoxFit.fill => 'fill',
    BoxFit.fitWidth => 'fitWidth',
    BoxFit.fitHeight => 'fitHeight',
    BoxFit.none => 'none',
    BoxFit.scaleDown => 'scaleDown',
  };
}

BoxFit? _fitFromString(String? value) {
  return switch (value) {
    'contain' => BoxFit.contain,
    'cover' => BoxFit.cover,
    'fill' => BoxFit.fill,
    'fitWidth' => BoxFit.fitWidth,
    'fitHeight' => BoxFit.fitHeight,
    'none' => BoxFit.none,
    'scaleDown' => BoxFit.scaleDown,
    _ => null,
  };
}
