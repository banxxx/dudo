import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_tokens.dart';
import '../../domain/reader_theme.dart';
import '../layout/reader_page_metrics.dart';
import 'progress/reader_chapter_progress_line.dart';
import 'progress/reader_time_battery_line.dart';

class ReaderProgress extends StatefulWidget {
  const ReaderProgress({
    super.key,
    required this.metrics,
    required this.palette,
    required this.pageLabel,
    required this.progress,
    required this.hideTimeBattery,
    required this.hideChapterProgress,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String pageLabel;
  final double progress;
  final bool hideTimeBattery;
  final bool hideChapterProgress;

  @override
  State<ReaderProgress> createState() => _ReaderProgressState();
}

class _ReaderProgressState extends State<ReaderProgress> {
  final Battery _battery = Battery();
  Timer? _clockTimer;
  StreamSubscription<BatteryState>? _batterySubscription;
  DateTime _now = DateTime.now();
  int? _batteryLevel;
  BatteryState? _batteryState;

  @override
  void initState() {
    super.initState();
    _loadBatteryInfo();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      _loadBatteryInfo();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = _batteryState ?? await _battery.batteryState;
      if (!mounted) return;
      setState(() {
        _batteryLevel = level.clamp(0, 100);
        _batteryState = state;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _batteryLevel = null;
        _batteryState = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideTimeBattery && widget.hideChapterProgress) {
      return const SizedBox.shrink();
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mutedColor =
        widget.palette.mutedForeground ?? DudoColors.textSecondary;
    final lines = <Widget>[
      if (!widget.hideChapterProgress)
        ReaderChapterProgressLine(
          metrics: widget.metrics,
          pageLabel: widget.pageLabel,
          progress: widget.progress,
          color: mutedColor,
        ),
      if (!widget.hideTimeBattery && !widget.hideChapterProgress)
        SizedBox(height: widget.metrics.s(3)),
      if (!widget.hideTimeBattery)
        ReaderTimeBatteryLine(
          metrics: widget.metrics,
          timeLabel: _timeLabel,
          batteryLabel: _batteryLabel,
          batteryIcon: _batteryIcon,
          color: mutedColor,
        ),
    ];

    return Positioned(
      key: const ValueKey('reader-progress'),
      left: widget.metrics.x(30),
      bottom: bottomInset + widget.metrics.s(10),
      width: widget.metrics.s(330),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }

  String get _timeLabel {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _batteryLabel {
    final level = _batteryLevel;
    if (level == null) return '--%';
    return '$level%';
  }

  IconData get _batteryIcon {
    final level = _batteryLevel;
    if (_batteryState == BatteryState.charging) {
      return LucideIcons.batteryCharging;
    }
    if (level == null) return LucideIcons.battery;
    if (level <= 10) return LucideIcons.batteryWarning;
    if (level <= 25) return LucideIcons.batteryLow;
    if (level <= 50) return LucideIcons.battery;
    if (level <= 75) return LucideIcons.batteryMedium;
    return LucideIcons.batteryFull;
  }
}
