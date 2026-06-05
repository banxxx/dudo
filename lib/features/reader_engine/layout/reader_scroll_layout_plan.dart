import 'reader_layout_models.dart';

class ReaderScrollLayoutPlan {
  const ReaderScrollLayoutPlan({
    required this.contentHeight,
    required this.blocks,
  });

  final double contentHeight;
  final List<ReaderBlockLayout> blocks;
}
