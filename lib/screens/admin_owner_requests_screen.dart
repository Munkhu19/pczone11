import 'package:flutter/material.dart';

import '../data/owner_application_store.dart';
import '../data/role_store.dart';
import '../l10n/app_localizations.dart';
import '../models/owner_application.dart';
import '../widgets/language_toggle_button.dart';

class AdminOwnerRequestsScreen extends StatefulWidget {
  const AdminOwnerRequestsScreen({super.key});

  @override
  State<AdminOwnerRequestsScreen> createState() => _AdminOwnerRequestsScreenState();
}

class _AdminOwnerRequestsScreenState extends State<AdminOwnerRequestsScreen> {
  List<OwnerApplication> _pendingRequests = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    RoleStore.rolesRevision.addListener(_loadPendingRequests);
    _loadPendingRequests();
  }

  @override
  void dispose() {
    RoleStore.rolesRevision.removeListener(_loadPendingRequests);
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    final requests = await RoleStore.pendingOwnerRequests();
    final applications = await OwnerApplicationStore.allApplications();
    final pendingApplications = requests
        .map(
          (entry) =>
              applications[entry.key] ??
              OwnerApplication(
                email: entry.key,
                centerName: '',
                phone: '',
                address: '',
                contactLink: '',
                note: '',
                requestedAt: DateTime.now(),
              ),
        )
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _pendingRequests = pendingApplications;
      _isLoading = false;
    });
  }

  Future<void> _resolveOwnerRequest({
    required String email,
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await RoleStore.saveRole(
      email: email,
      role: approve ? RoleStore.ownerRole : RoleStore.customerRole,
    );
    await OwnerApplicationStore.removeApplication(email);
    await _loadPendingRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? l10n.ownerRequestApproved(email)
              : l10n.ownerRequestRejected(email),
        ),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ownerRequestsTitle),
        actions: const [AppHeaderActions()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Text(
                    l10n.ownerRequestsEmpty,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final entry = _pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (entry.centerName.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _RequestInfoRow(
                                icon: Icons.storefront_outlined,
                                label: l10n.ownerApplicationCenterName,
                                value: entry.centerName,
                              ),
                            ],
                            if (entry.phone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _RequestInfoRow(
                                icon: Icons.call_outlined,
                                label: l10n.ownerApplicationPhone,
                                value: entry.phone,
                              ),
                            ],
                            if (entry.address.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _RequestInfoRow(
                                icon: Icons.location_on_outlined,
                                label: l10n.ownerApplicationAddress,
                                value: entry.address,
                              ),
                            ],
                            if (entry.contactLink.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _RequestInfoRow(
                                icon: Icons.link_outlined,
                                label: l10n.ownerApplicationLink,
                                value: entry.contactLink,
                              ),
                            ],
                            if (entry.note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _RequestInfoRow(
                                icon: Icons.notes_outlined,
                                label: l10n.ownerApplicationNote,
                                value: entry.note,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _RequestInfoRow(
                              icon: Icons.event_available_outlined,
                              label: l10n.profileCreatedAtLabel,
                              value:
                                  '${entry.requestedAt.year.toString().padLeft(4, '0')}-${entry.requestedAt.month.toString().padLeft(2, '0')}-${entry.requestedAt.day.toString().padLeft(2, '0')} ${entry.requestedAt.hour.toString().padLeft(2, '0')}:${entry.requestedAt.minute.toString().padLeft(2, '0')}',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _resolveOwnerRequest(
                                      email: entry.email,
                                      approve: false,
                                    ),
                                    child: Text(l10n.ownerRejectAction),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _resolveOwnerRequest(
                                      email: entry.email,
                                      approve: true,
                                    ),
                                    child: Text(l10n.ownerApproveAction),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  const _RequestInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
