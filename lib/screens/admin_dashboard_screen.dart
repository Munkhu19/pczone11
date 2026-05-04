import 'package:flutter/material.dart';

import '../data/center_store.dart';
import '../data/role_store.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../widgets/language_toggle_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<int>(
      valueListenable: RoleStore.rolesRevision,
      builder: (context, revision, child) {
        return FutureBuilder<Map<String, String>>(
          future: RoleStore.allRoles(),
          builder: (context, roleSnapshot) {
            final roles = roleSnapshot.data ?? const <String, String>{};
            final pendingCount = roles.values
                .where((role) => role == RoleStore.ownerPendingRole)
                .length;
            final ownerCount =
                roles.values.where((role) => role == RoleStore.ownerRole).length;
            final customerCount = roles.values
                .where((role) => role == RoleStore.customerRole)
                .length;
            final adminCount =
                roles.values.where((role) => role == RoleStore.adminRole).length;

            return ValueListenableBuilder<List<EsportCenter>>(
              valueListenable: CenterStore.centersNotifier,
              builder: (context, centers, child) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(l10n.adminDashboardTitle),
                    actions: const [AppHeaderActions()],
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _AdminStatCard(
                        title: l10n.adminPendingRequests,
                        value: pendingCount.toString(),
                        color: const Color(0xFFF59E0B),
                      ),
                      _AdminStatCard(
                        title: l10n.adminOwnersCount,
                        value: ownerCount.toString(),
                        color: const Color(0xFF0F766E),
                      ),
                      _AdminStatCard(
                        title: l10n.adminCustomersCount,
                        value: customerCount.toString(),
                        color: const Color(0xFF7C3AED),
                      ),
                      _AdminStatCard(
                        title: l10n.adminAdminsCount,
                        value: adminCount.toString(),
                        color: const Color(0xFFDC2626),
                      ),
                      _AdminStatCard(
                        title: l10n.adminCentersCount,
                        value: centers.length.toString(),
                        color: const Color(0xFF1D4ED8),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
