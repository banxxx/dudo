import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'app_message_service.dart';

class AppMessageHost extends ConsumerStatefulWidget {
  const AppMessageHost({
    super.key,
    required this.child,
    this.routeInformationProvider,
  });

  final Widget child;
  final RouteInformationProvider? routeInformationProvider;

  @override
  ConsumerState<AppMessageHost> createState() => _AppMessageHostState();
}

class _AppMessageHostState extends ConsumerState<AppMessageHost> {
  RouteInformationProvider? _routeInformationProvider;
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    _syncRouteProvider(widget.routeInformationProvider);
  }

  @override
  void didUpdateWidget(covariant AppMessageHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.routeInformationProvider,
      widget.routeInformationProvider,
    )) {
      _syncRouteProvider(widget.routeInformationProvider);
    }
  }

  @override
  void dispose() {
    _routeInformationProvider?.removeListener(_handleRouteChanged);
    super.dispose();
  }

  void _syncRouteProvider(RouteInformationProvider? nextProvider) {
    if (identical(_routeInformationProvider, nextProvider)) return;

    _routeInformationProvider?.removeListener(_handleRouteChanged);
    _routeInformationProvider = nextProvider;
    _lastRoute = _currentRoute();
    _routeInformationProvider?.addListener(_handleRouteChanged);
  }

  void _handleRouteChanged() {
    final currentRoute = _currentRoute();
    if (currentRoute == null || currentRoute == _lastRoute) return;
    _lastRoute = currentRoute;
    ref.read(appMessageServiceProvider).dismissAll();
  }

  String? _currentRoute() {
    return _routeInformationProvider?.value.uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(child: widget.child);
  }
}
