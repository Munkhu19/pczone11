import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

final ValueNotifier<int> rootShellTabNotifier = ValueNotifier<int>(0);

class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _currentIndex;

  late final List<Widget> _tabs = const [
    HomeScreen(),
    CenterMapScreen(),
    BookingHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    rootShellTabNotifier.value = _currentIndex;
    rootShellTabNotifier.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    rootShellTabNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || _currentIndex == rootShellTabNotifier.value) return;
    setState(() {
      _currentIndex = rootShellTabNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: '',
                tooltip: l10n.homeTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map_rounded),
                label: '',
                tooltip: l10n.mapTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
                label: '',
                tooltip: l10n.bookingHistoryTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: '',
                tooltip: l10n.profileTitle,
              ),
            ],
            onDestinationSelected: (index) {
              rootShellTabNotifier.value = index;
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
