String timeGreeting({DateTime? dateTime}) {
  final hour = (dateTime ?? DateTime.now()).hour;

  if (hour >= 5 && hour < 11) {
    return '早上好';
  }
  if (hour >= 11 && hour < 14) {
    return '中午好';
  }
  if (hour >= 17 && hour < 19) {
    return '傍晚好';
  }
  if (hour >= 19 && hour < 23) {
    return '晚上好';
  }
  return '夜深了';
}
