import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_avatar_store.dart';
import '../data/firebase_state.dart';
import '../data/owner_application_store.dart';
import '../data/role_store.dart';
import '../l10n/app_localizations.dart';
import '../models/owner_application.dart';
import 'owner_application_form_screen.dart';
import '../widgets/language_toggle_button.dart';

ImageProvider<Object>? _buildAvatarImageProvider({
  required Uint8List? localAvatarBytes,
  required String? cachedAvatarUrl,
  required User? user,
}) {
  if (localAvatarBytes != null) {
    return MemoryImage(localAvatarBytes);
  }
  final photoUrl = user?.photoURL;
  if (photoUrl != null &&
      photoUrl.isNotEmpty &&
      (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
    return NetworkImage(photoUrl);
  }
  if (cachedAvatarUrl != null && cachedAvatarUrl.isNotEmpty) {
    return NetworkImage(cachedAvatarUrl);
  }
  return null;
}

Future<String?> _findStoredAvatarUrl(String uid) async {
  final stored = await ProfileAvatarStore.loadPhotoUrl(uid);
  if (stored != null && stored.isNotEmpty) {
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }
    try {
      if (stored.startsWith('gs://')) {
        return await FirebaseStorage.instance.refFromURL(stored).getDownloadURL();
      }
      return await FirebaseStorage.instance.ref().child(stored).getDownloadURL();
    } on FirebaseException {
      return stored;
    }
  }

  final ref = FirebaseStorage.instance.ref().child('avatars');
  final candidates = <String>[
    '$uid.jpg',
    '$uid.jpeg',
    '$uid.png',
    '$uid.webp',
  ];

  for (final name in candidates) {
    try {
      return await ref.child(name).getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        debugPrint('Avatar lookup failed for $name: ${e.code} ${e.message}');
      }
    }
  }

  return null;
}

Future<String?> _normalizeAvatarUrl(String? raw) async {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  try {
    if (raw.startsWith('gs://')) {
      return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
    }
    return await FirebaseStorage.instance.ref().child(raw).getDownloadURL();
  } on FirebaseException {
    return raw;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _role = RoleStore.customerRole;
  Uint8List? _localAvatarBytes;
  String? _cachedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadRole();
    if (!firebaseAvailable) return;
    _loadLocalAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUser();
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _loadRole() async {
    final email = firebaseAvailable ? FirebaseAuth.instance.currentUser?.email : null;
    final role = await RoleStore.roleForEmail(email);
    if (!mounted) return;
    setState(() {
      _role = role;
    });
  }

  Future<void> _loadLocalAvatar() async {
    if (!firebaseAvailable) return;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;
    final bytes = await ProfileAvatarStore.load(uid);
    final cachedUrl = await ProfileAvatarStore.loadPhotoUrl(uid);
    final restoredUrl = await _normalizeAvatarUrl(user?.photoURL) ??
        await _findStoredAvatarUrl(uid);
    if (restoredUrl != null && restoredUrl.isNotEmpty) {
      await ProfileAvatarStore.savePhotoUrl(uid: uid, photoUrl: restoredUrl);
      if (user != null && (user.photoURL == null || user.photoURL!.isEmpty)) {
        try {
          await user.updatePhotoURL(restoredUrl);
          await user.reload();
        } on FirebaseAuthException catch (e) {
          debugPrint('Failed to restore avatar URL in auth: ${e.code} ${e.message}');
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _localAvatarBytes = bytes;
      _cachedAvatarUrl = restoredUrl ?? cachedUrl;
    });
  }

  Future<void> _refreshUser() async {
    if (!firebaseAvailable) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      await _loadLocalAvatar();
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to refresh profile user: ${e.code} ${e.message}');
    }
    if (!mounted) return;
    setState(() {});
  }

  ImageProvider<Object>? _avatarImageProvider(User? user) {
    return _buildAvatarImageProvider(
      localAvatarBytes: _localAvatarBytes,
      cachedAvatarUrl: _cachedAvatarUrl,
      user: user,
    );
  }

  String _roleLabel(AppLocalizations l10n) {
    if (_role == RoleStore.adminRole) return l10n.adminRoleLabel;
    if (_role == RoleStore.ownerRole) return l10n.ownerRoleOwner;
    if (_role == RoleStore.ownerPendingRole) return l10n.ownerRolePending;
    return l10n.ownerRoleCustomer;
  }

  Future<void> _logout() async {
    if (!firebaseAvailable) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Color _roleColor() {
    return _role == RoleStore.adminRole
        ? const Color(0xFFDC2626)
        : _role == RoleStore.ownerRole
        ? const Color(0xFF0F766E)
        : _role == RoleStore.ownerPendingRole
            ? const Color(0xFFF59E0B)
        : const Color(0xFF7C3AED);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileSettingsScreen(role: _role),
      ),
    );
    if (!mounted) return;
    await _loadRole();
    await _loadLocalAvatar();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final listBottomPadding = bottomInset + 112;
    if (!firebaseAvailable) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileTitle),
          actions: const [AppHeaderActions()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.authFirebaseNotInitialized,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final metadata = user?.metadata;
    final roleColor = _roleColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: const [AppHeaderActions()],
      ),
      body: user == null
          ? Center(child: Text(l10n.profileNotSignedIn))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPadding),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor.withValues(alpha: 0.95),
                        const Color(0xFF1E293B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                            backgroundImage: _avatarImageProvider(user),
                            child: _avatarImageProvider(user) == null
                                ? const Icon(
                                    Icons.person,
                                    size: 46,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            top: -8,
                            right: -10,
                            child: IconButton.filledTonal(
                              onPressed: _openSettings,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.settings_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : l10n.profileNoDisplayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _roleLabel(l10n),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user.email ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, color: roleColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.profileAccountSection,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SelectableText(
                          user.email ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _roleLabel(l10n),
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(l10n.profileUidLabel(user.uid)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history_outlined, color: roleColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.profileActivitySection,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          text: l10n.createdLabel(_formatDate(metadata?.creationTime)),
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: Icons.login_outlined,
                          text: l10n.profileLastSignInLabel(
                            _formatDate(metadata?.lastSignInTime),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                        title: Text(l10n.logout),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileSettingsScreen extends StatefulWidget {
  const _ProfileSettingsScreen({required this.role});

  final String role;

  @override
  State<_ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<_ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isRefreshingVerification = false;
  Uint8List? _localAvatarBytes;
  String? _cachedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _loadLocalAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUser();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _loadLocalAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;
    final bytes = await ProfileAvatarStore.load(uid);
    final cachedUrl = await ProfileAvatarStore.loadPhotoUrl(uid);
    final restoredUrl = await _normalizeAvatarUrl(user?.photoURL) ??
        await _findStoredAvatarUrl(uid);
    if (restoredUrl != null && restoredUrl.isNotEmpty) {
      await ProfileAvatarStore.savePhotoUrl(uid: uid, photoUrl: restoredUrl);
      if (user != null && (user.photoURL == null || user.photoURL!.isEmpty)) {
        try {
          await user.updatePhotoURL(restoredUrl);
          await user.reload();
        } on FirebaseAuthException catch (e) {
          debugPrint('Failed to restore avatar URL in auth: ${e.code} ${e.message}');
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _localAvatarBytes = bytes;
      _cachedAvatarUrl = restoredUrl ?? cachedUrl;
    });
  }

  ImageProvider<Object>? _avatarImageProvider(User? user) {
    return _buildAvatarImageProvider(
      localAvatarBytes: _localAvatarBytes,
      cachedAvatarUrl: _cachedAvatarUrl,
      user: user,
    );
  }

  String _roleLabel(AppLocalizations l10n) {
    if (widget.role == RoleStore.adminRole) return l10n.adminRoleLabel;
    if (widget.role == RoleStore.ownerRole) return l10n.ownerRoleOwner;
    if (widget.role == RoleStore.ownerPendingRole) {
      return l10n.ownerRolePending;
    }
    return l10n.ownerRoleCustomer;
  }

  Color _roleColor() {
    return widget.role == RoleStore.adminRole
        ? const Color(0xFFDC2626)
        : widget.role == RoleStore.ownerRole
        ? const Color(0xFF0F766E)
        : widget.role == RoleStore.ownerPendingRole
            ? const Color(0xFFF59E0B)
        : const Color(0xFF7C3AED);
  }

  Future<void> _applyAsOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return;
    final initialApplication = await OwnerApplicationStore.applicationForEmail(
      email,
    );
    if (!mounted) return;
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OwnerApplicationFormScreen(
          email: email,
          initialApplication: initialApplication,
        ),
      ),
    );
    if (submitted == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<OwnerApplication?> _loadPendingApplication() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      return Future<OwnerApplication?>.value(null);
    }
    return OwnerApplicationStore.applicationForEmail(email);
  }

  Future<void> _refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isRefreshingVerification) return;

    setState(() {
      _isRefreshingVerification = true;
    });
    try {
      await user.reload();
      await _loadLocalAvatar();
    } finally {
      if (mounted) {
        _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
        setState(() {
          _isRefreshingVerification = false;
        });
      }
    }
  }

  Future<void> _saveDisplayName() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final nextName = _nameController.text.trim();
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });
    try {
      await user.updateDisplayName(nextName.isEmpty ? null : nextName);
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdated),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.profileUpdateFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final Uint8List data = await picked.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      await ProfileAvatarStore.save(uid: user.uid, bytes: data);
      await ProfileAvatarStore.savePhotoUrl(
        uid: user.uid,
        photoUrl: downloadUrl,
      );
      if (!mounted) return;

      setState(() {
        _localAvatarBytes = data;
        _cachedAvatarUrl = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileAvatarUpdated),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      setState(() {});
    } on FirebaseException catch (e) {
      debugPrint('Avatar upload failed: ${e.code} ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.profileAvatarUpdateFailed} (${e.code})'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileAvatarUpdateFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _copyValue(String value, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  Future<void> _sendPasswordReset() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profilePasswordResetSent(email)),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.authUnknownError)),
      );
    }
  }

  Future<void> _sendEmailVerification() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();
      await user.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.profileVerificationSent(user.email ?? ''),
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.authUnknownError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final metadata = user?.metadata;
    final roleColor = _roleColor();
    final isEmailVerified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileSettingsTitle),
        actions: const [AppHeaderActions()],
      ),
      body: user == null
          ? Center(child: Text(l10n.profileNotSignedIn))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: _avatarImageProvider(user),
                          child: _avatarImageProvider(user) == null
                              ? const Icon(Icons.person, size: 44)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isUploadingAvatar ? null : _pickAndUploadAvatar,
                            icon: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_outlined),
                            label: Text(l10n.profileAvatarUpload),
                          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.profileDisplayNameLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveDisplayName,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.profileSaveButton),
                          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SettingsInfoRow(
                          icon: Icons.mail_outline,
                          label: l10n.email,
                          value: user.email ?? '-',
                          trailing: user.email == null
                              ? null
                              : IconButton(
                                  onPressed: () => _copyValue(
                                    user.email!,
                                    l10n.profileEmailCopied,
                                  ),
                                  icon: const Icon(Icons.copy_outlined, size: 18),
                                  tooltip: l10n.profileCopyAction,
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: l10n.profileRoleLabel,
                          value: _roleLabel(l10n),
                          valueColor: roleColor,
                        ),
                        if (widget.role == RoleStore.customerRole) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _applyAsOwner,
                              icon: const Icon(Icons.storefront_outlined),
                              label: Text(l10n.ownerApplyAction),
                            ),
                          ),
                        ] else if (widget.role == RoleStore.ownerPendingRole) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.ownerPendingInline,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<OwnerApplication?>(
                            future: _loadPendingApplication(),
                            builder: (context, snapshot) {
                              final application = snapshot.data;
                              if (application == null) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  _SettingsInfoRow(
                                    icon: Icons.storefront_outlined,
                                    label: l10n.ownerApplicationCenterName,
                                    value: application.centerName,
                                  ),
                                  const SizedBox(height: 12),
                                  _SettingsInfoRow(
                                    icon: Icons.call_outlined,
                                    label: l10n.ownerApplicationPhone,
                                    value: application.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  _SettingsInfoRow(
                                    icon: Icons.location_on_outlined,
                                    label: l10n.ownerApplicationAddress,
                                    value: application.address,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SettingsInfoRow(
                          icon: isEmailVerified
                              ? Icons.verified_outlined
                              : Icons.mark_email_unread_outlined,
                          label: l10n.profileEmailVerificationTitle,
                          value: isEmailVerified
                              ? l10n.profileEmailVerified
                              : l10n.profileEmailNotVerified,
                          valueColor: isEmailVerified
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF59E0B),
                          trailing: isEmailVerified
                              ? IconButton(
                                  onPressed: _refreshUser,
                                  icon: const Icon(Icons.refresh_outlined, size: 18),
                                  tooltip: l10n.profileRefreshVerification,
                                )
                              : TextButton(
                                  onPressed: _isRefreshingVerification
                                      ? null
                                      : _sendEmailVerification,
                                  child: Text(l10n.profileSendVerification),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsInfoRow(
                          icon: Icons.fingerprint,
                          label: l10n.profileUidTitle,
                          value: user.uid,
                          selectable: true,
                          trailing: IconButton(
                            onPressed: () => _copyValue(
                              user.uid,
                              l10n.profileUidCopied,
                            ),
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            tooltip: l10n.profileCopyAction,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsInfoRow(
                          icon: Icons.event_available_outlined,
                          label: l10n.profileCreatedAtLabel,
                          value: _formatDate(metadata?.creationTime),
                        ),
                        const SizedBox(height: 12),
                        _SettingsInfoRow(
                          icon: Icons.login_outlined,
                          label: l10n.profileLastSignInTitle,
                          value: _formatDate(metadata?.lastSignInTime),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _sendPasswordReset,
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: Text(l10n.profileChangePassword),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: secondaryColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selectable;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: valueColor,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 3),
              selectable
                  ? SelectableText(value, style: valueStyle)
                  : Text(value, style: valueStyle),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
