import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../layout/reader_page_metrics.dart';

class ReaderProgress extends StatefulWidget {
  const ReaderProgress({
    super.key,
    required this.metrics,
    required this.palette,
    required this.pageLabel,
    required this.progress,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final String pageLabel;
  final double progress;

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mutedColor =
        widget.palette.mutedForeground ?? DudoColors.textSecondary;
    final textStyle = DudoTextStyles.sans(
      color: mutedColor,
      fontSize: widget.metrics.s(12),
      fontWeight: FontWeight.w600,
    );
    final numericStyle = DudoTextStyles.numeric(
      color: mutedColor,
      fontSize: widget.metrics.s(12),
      fontWeight: FontWeight.w600,
    );

    return Positioned(
      key: const ValueKey('reader-progress'),
      left: widget.metrics.x(30),
      bottom: bottomInset + widget.metrics.s(10),
      width: widget.metrics.s(330),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.pageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              SizedBox(width: widget.metrics.s(16)),
              Text(
                '${(widget.progress * 100).round()}%',
                style: numericStyle,
              ),
            ],
          ),
          SizedBox(height: widget.metrics.s(3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_timeLabel, style: numericStyle),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _batteryIcon,
                    size: widget.metrics.s(15),
                    color: mutedColor,
                  ),
                  SizedBox(width: widget.metrics.s(4)),
                  Text(_batteryLabel, style: numericStyle),
                ],
              ),
            ],
          ),
        ],
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
