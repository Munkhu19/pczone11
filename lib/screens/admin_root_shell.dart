import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'admin_centers_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_owner_requests_screen.dart';
import 'admin_users_screen.dart';
import 'profile_screen.dart';

class AdminRootShell extends StatefulWidget {
  const AdminRootShell({super.key});

  @override
  State<AdminRootShell> createState() => _AdminRootShellState();
}

class _AdminRootShellState extends State<AdminRootShell> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = const [
    AdminDashboardScreen(),
    AdminOwnerRequestsScreen(),
    AdminCentersScreen(),
    AdminUsersScreen(),
    ProfileScreen(),
  ];

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
                icon: const Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: const Icon(Icons.admin_panel_settings),
                label: '',
                tooltip: l10n.adminDashboardTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.pending_actions_outlined),
                selectedIcon: const Icon(Icons.pending_actions),
                label: '',
                tooltip: l10n.ownerRequestsTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded),
                label: '',
                tooltip: l10n.adminCentersTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.group_outlined),
                selectedIcon: const Icon(Icons.group),
                label: '',
                tooltip: l10n.adminUsersTitle,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: '',
                tooltip: l10n.profileTitle,
              ),
            ],
            onDestinationSelected: (index) {
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
