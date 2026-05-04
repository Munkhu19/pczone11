import 'package:flutter/material.dart';

import '../data/owner_application_store.dart';
import '../data/role_store.dart';
import '../l10n/app_localizations.dart';
import '../models/owner_application.dart';

class OwnerApplicationFormScreen extends StatefulWidget {
  const OwnerApplicationFormScreen({
    super.key,
    required this.email,
    this.initialApplication,
  });

  final String email;
  final OwnerApplication? initialApplication;

  @override
  State<OwnerApplicationFormScreen> createState() =>
      _OwnerApplicationFormScreenState();
}

class _OwnerApplicationFormScreenState extends State<OwnerApplicationFormScreen> {
  late final TextEditingController _centerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactLinkController;
  late final TextEditingController _noteController;
  final _centerNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _contactLinkFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialApplication;
    _centerNameController = TextEditingController(
      text: initial?.centerName ?? '',
    );
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _addressController = TextEditingController(text: initial?.address ?? '');
    _contactLinkController = TextEditingController(
      text: initial?.contactLink ?? '',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactLinkController.dispose();
    _noteController.dispose();
    _centerNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _contactLinkFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final centerName = _centerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final contactLink = _contactLinkController.text.trim();
    final note = _noteController.text.trim();

    if (centerName.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ownerApplicationRequiredFields)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    await RoleStore.saveRole(
      email: widget.email,
      role: RoleStore.ownerPendingRole,
    );
    await OwnerApplicationStore.saveApplication(
      OwnerApplication(
        email: widget.email,
        centerName: centerName,
        phone: phone,
        address: address,
        contactLink: contactLink,
        note: note,
        requestedAt: widget.initialApplication?.requestedAt ?? DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.ownerApplySubmitted),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
    Navigator.of(context).pop(true);
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerApplicationFormTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ownerApplicationFormSubtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _centerNameController,
                    focusNode: _centerNameFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocusNode),
                    decoration: _decoration(
                      label: l10n.ownerApplicationCenterName,
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_addressFocusNode),
                    decoration: _decoration(
                      label: l10n.ownerApplicationPhone,
                      icon: Icons.call_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_contactLinkFocusNode),
                    decoration: _decoration(
                      label: l10n.ownerApplicationAddress,
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactLinkController,
                    focusNode: _contactLinkFocusNode,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_noteFocusNode),
                    decoration: _decoration(
                      label: l10n.ownerApplicationLink,
                      icon: Icons.link_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      _submit();
                    },
                    decoration: _decoration(
                      label: l10n.ownerApplicationNote,
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.ownerApplicationSubmit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
