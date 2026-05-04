import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: child,
    );
  }
}
