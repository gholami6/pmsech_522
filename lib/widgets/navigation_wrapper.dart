import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final bool showBackButton;

  const NavigationWrapper({
    Key? key,
    required this.child,
    required this.currentRoute,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final navigationService = NavigationService();
          await navigationService.handleBackNavigation(context, currentRoute);
        }
      },
      child: child,
    );
  }
}
