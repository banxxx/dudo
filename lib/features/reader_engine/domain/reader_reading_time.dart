String estimateReaderReadingTimeText(String content) {
  final readableLength = content.replaceAll(RegExp(r'\s+'), '').length;
  if (readableLength == 0) return '';
  final minutes = (readableLength / 450).ceil().clamp(1, 9999);
  return '约 $minutes 分钟';
}
