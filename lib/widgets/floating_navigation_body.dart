import 'package:flutter/material.dart';

class FloatingNavigationBody extends StatelessWidget {
  const FloatingNavigationBody({
    super.key,
    required this.child,
    this.reserveBottomSpace = true,
  });

  final Widget child;
  final bool reserveBottomSpace;

  @override
  Widget build(BuildContext context) {
    if (!reserveBottomSpace) return child;

    final navigationBarHeight =
        NavigationBarTheme.of(context).height ?? _defaultNavigationBarHeight;
    final bottomPadding = navigationBarHeight + _navigationBarMargin;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: child,
    );
  }
}

const _defaultNavigationBarHeight = 80.0;
const _navigationBarMargin = 12.0;
