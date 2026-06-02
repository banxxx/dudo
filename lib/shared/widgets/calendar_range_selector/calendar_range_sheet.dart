import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_tokens.dart';
import 'calendar_range_models.dart';
import 'calendar_range_selector.dart';

Future<CalendarDateRangeSelection?> showCalendarRangeSelectorSheet({
  required BuildContext context,
  required CalendarDateRangeSelection initialSelection,
  DateTime? today,
  DateTime? minDate,
  DateTime? maxDate,
  String? summaryText,
  String Function(CalendarDateRangeSelection selection)? summaryTextBuilder,
}) {
  return showModalBottomSheet<CalendarDateRangeSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CalendarRangeSelectorSheet(
      initialSelection: initialSelection,
      today: today,
      minDate: minDate,
      maxDate: maxDate,
      summaryText: summaryText,
      summaryTextBuilder: summaryTextBuilder,
    ),
  );
}

class CalendarRangeSelectorSheet extends StatefulWidget {
  const CalendarRangeSelectorSheet({
    super.key,
    required this.initialSelection,
    this.today,
    this.minDate,
    this.maxDate,
    this.summaryText,
    this.summaryTextBuilder,
  });

  final CalendarDateRangeSelection initialSelection;
  final DateTime? today;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String? summaryText;
  final String Function(CalendarDateRangeSelection selection)?
      summaryTextBuilder;

  @override
  State<CalendarRangeSelectorSheet> createState() =>
      _CalendarRangeSelectorSheetState();
}

class _CalendarRangeSelectorSheetState
    extends State<CalendarRangeSelectorSheet> {
  late CalendarDateRangeSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final summaryText =
        widget.summaryTextBuilder?.call(_selection) ?? widget.summaryText;

    return Container(
      height: 574,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: DudoColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3325251F),
            offset: Offset(0, -18),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: DudoColors.outline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selection.preset == CalendarRangePreset.custom
                        ? '自定义时间'
                        : '选择时间',
                    style: DudoTextStyles.serif(
                      color: DudoColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SheetIconButton(
                  icon: LucideIcons.x,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CalendarRangeSelector(
                selection: _selection,
                today: widget.today,
                minDate: widget.minDate,
                maxDate: widget.maxDate,
                summaryText: summaryText,
                onSelectionChanged: (selection) {
                  setState(() => _selection = selection);
                },
                onConfirm: () => Navigator.of(context).pop(_selection),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DudoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DudoColors.outlineVariant),
          ),
          child: Icon(icon, color: DudoColors.secondary, size: 21),
        ),
      ),
    );
  }
}
