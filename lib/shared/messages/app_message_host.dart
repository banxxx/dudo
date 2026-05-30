import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

class AppMessageHost extends StatelessWidget {
  const AppMessageHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(child: child);
  }
}
