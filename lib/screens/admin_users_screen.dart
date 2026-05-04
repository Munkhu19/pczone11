import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/center_store.dart';
import '../data/owner_application_store.dart';
import '../data/role_store.dart';
import '../data/user_directory_store.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isDeleting = false;

  Future<Map<String, String>> _loadUsers() async {
    final roles = await RoleStore.allRoles();
    final applications = await OwnerApplicationStore.allApplications();
    final registeredUsers = await UserDirectoryStore.all();
    final bookingEmails = BookingStore.bookingHistory()
        .map((booking) => booking.createdByEmail)
        .whereType<String>()
        .where((email) => email.isNotEmpty)
        .toSet();
    final centerOwnerEmails = CenterStore.all()
        .map((center) => center.ownerEmail)
        .whereType<String>()
        .where((email) => email.isNotEmpty)
        .toSet();

    final knownEmails = <String>{
      ...registeredUsers,
      ...roles.keys,
      ...applications.keys,
      ...bookingEmails,
    };

    final linkedOwnerEmails = centerOwnerEmails.where(
      (email) =>
          registeredUsers.contains(email) ||
          roles.containsKey(email) ||
          applications.containsKey(email) ||
          bookingEmails.contains(email),
    );
    knownEmails.addAll(linkedOwnerEmails);

    final users = <String, String>{};
    for (final email in knownEmails) {
      users[email] = roles[email] ?? RoleStore.customerRole;
    }
    return users;
  }

  Future<void> _deleteUser({
    required String email,
    required String role,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteUserTitle),
        content: Text(l10n.adminDeleteUserMessage(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.adminDeleteUserAction),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });
    try {
      final ownedCenterIds = CenterStore.ownedBy(email).map((e) => e.id).toSet();
      if (ownedCenterIds.isNotEmpty) {
        await BookingStore.removeCenters(ownedCenterIds);
        await CenterStore.deleteCenters(ownedCenterIds);
      }
      await BookingStore.removeBookingsByCreator(createdByEmail: email);
      await OwnerApplicationStore.removeApplication(email);
      await UserDirectoryStore.remove(email);
      if (role != RoleStore.adminRole) {
        await RoleStore.removeRole(email);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminUserDeleted(email)),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case RoleStore.adminRole:
        return l10n.adminRoleLabel;
      case RoleStore.ownerRole:
        return l10n.ownerRoleOwner;
      case RoleStore.ownerPendingRole:
        return l10n.ownerRolePending;
      default:
        return l10n.ownerRoleCustomer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<int>(
        valueListenable: RoleStore.rolesRevision,
        builder: (context, revision, child) {
          return FutureBuilder<Map<String, String>>(
          future: _loadUsers(),
          builder: (context, snapshot) {
            final roles = snapshot.data ?? const <String, String>{};
            final entries = roles.entries.toList(growable: false)
              ..sort((a, b) => a.key.compareTo(b.key));

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.adminUsersTitle),
                actions: const [AppHeaderActions()],
              ),
              body: entries.isEmpty
                  ? Center(child: Text(l10n.adminUsersEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isProtectedAdmin = entry.value == RoleStore.adminRole;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text(_roleLabel(l10n, entry.value)),
                            trailing: IconButton(
                              onPressed: _isDeleting || isProtectedAdmin
                                  ? null
                                  : () => _deleteUser(
                                        email: entry.key,
                                        role: entry.value,
                                      ),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: isProtectedAdmin
                                  ? l10n.adminDeleteUserProtected
                                  : l10n.adminDeleteUserAction,
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
