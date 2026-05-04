import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_state.dart';
import '../data/owner_application_store.dart';
import '../data/role_store.dart';
import '../data/user_directory_store.dart';
import '../l10n/app_localizations.dart';
import '../models/owner_application.dart';
import '../widgets/language_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final ownerCenterNameController = TextEditingController();
  final ownerPhoneController = TextEditingController();
  final ownerAddressController = TextEditingController();
  final ownerLinkController = TextEditingController();
  final ownerNoteController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _ownerCenterNameFocusNode = FocusNode();
  final _ownerPhoneFocusNode = FocusNode();
  final _ownerAddressFocusNode = FocusNode();
  final _ownerLinkFocusNode = FocusNode();
  final _ownerNoteFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _requestOwnerAccessOnSignUp = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ownerCenterNameController.dispose();
    ownerPhoneController.dispose();
    ownerAddressController.dispose();
    ownerLinkController.dispose();
    ownerNoteController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _ownerCenterNameFocusNode.dispose();
    _ownerPhoneFocusNode.dispose();
    _ownerAddressFocusNode.dispose();
    _ownerLinkFocusNode.dispose();
    _ownerNoteFocusNode.dispose();
    super.dispose();
  }

  String _authErrorMessage(AppLocalizations l10n, String code) {
    switch (code) {
      case 'invalid-email':
        return l10n.authInvalidEmail;
      case 'operation-not-allowed':
        return l10n.authEmailPasswordNotEnabled;
      case 'user-disabled':
        return l10n.authUserDisabled;
      case 'too-many-requests':
        return l10n.authTooManyRequests;
      case 'invalid-api-key':
      case 'api-key-not-valid.-please-pass-a-valid-api-key.':
        return l10n.authApiKeyInvalid;
      case 'network-request-failed':
        return l10n.authNetworkError;
      case 'email-already-in-use':
        return l10n.usernameAlreadyExists;
      case 'weak-password':
        return l10n.authWeakPassword;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.invalidCredentials;
      default:
        return l10n.authUnknownError;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  Future<void> _submitAuth() async {
    final l10n = AppLocalizations.of(context)!;
    if (!firebaseAvailable) {
      _showError(l10n.authFirebaseNotInitialized);
      return;
    }

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final ownerCenterName = ownerCenterNameController.text.trim();
    final ownerPhone = ownerPhoneController.text.trim();
    final ownerAddress = ownerAddressController.text.trim();
    final ownerLink = ownerLinkController.text.trim();
    final ownerNote = ownerNoteController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(l10n.fillAllFields);
      return;
    }
    if (_isSignUp && password != confirmPassword) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }
    if (_isSignUp &&
        _requestOwnerAccessOnSignUp &&
        (ownerCenterName.isEmpty || ownerPhone.isEmpty || ownerAddress.isEmpty)) {
      _showError(l10n.ownerApplicationRequiredFields);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    if (_isSignUp) {
      authFlowInProgress.value = true;
    }

    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await UserDirectoryStore.register(email);
        await RoleStore.saveRole(
          email: email,
          role: _requestOwnerAccessOnSignUp
              ? RoleStore.ownerPendingRole
              : RoleStore.customerRole,
        );
        if (_requestOwnerAccessOnSignUp) {
          await OwnerApplicationStore.saveApplication(
            OwnerApplication(
              email: email,
              centerName: ownerCenterName,
              phone: ownerPhone,
              address: ownerAddress,
              contactLink: ownerLink,
              note: ownerNote,
              requestedAt: DateTime.now(),
            ),
          );
        }
        if (!mounted) return;
        setState(() {
          _isSignUp = false;
          _requestOwnerAccessOnSignUp = false;
        });
        ownerCenterNameController.clear();
        ownerPhoneController.clear();
        ownerAddressController.clear();
        ownerLinkController.clear();
        ownerNoteController.clear();
        _showSuccess(l10n.accountCreated);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await UserDirectoryStore.register(email);
        if (!RoleStore.isAdminEmail(email)) {
          final existingRole = await RoleStore.roleForEmail(email);
          if (existingRole == RoleStore.customerRole) {
            await RoleStore.saveRole(
              email: email,
              role: RoleStore.customerRole,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(l10n, e.code));
    } catch (_) {
      _showError(l10n.authUnknownError);
    } finally {
      if (_isSignUp) {
        authFlowInProgress.value = false;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0F766E),
      ),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF081120).withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.96),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
              : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF14B8A6),
          width: 1.6,
        ),
      ),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFD6E4FF) : const Color(0xFF475569),
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0F766E),
      ),
    );
  }

  TextStyle _fieldTextStyle(BuildContext context) => TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF0F172A),
        fontSize: 16,
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    VoidCallback? onDone,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
          return;
        }
        FocusScope.of(context).unfocus();
        onDone?.call();
      },
      cursorColor: const Color(0xFF0F766E),
      style: _fieldTextStyle(context),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _buildOwnerRequestFields(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF081120).withValues(alpha: 0.74)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7C3AED).withValues(alpha: 0.28)
              : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _requestOwnerAccessOnSignUp,
            onChanged: (value) {
              setState(() {
                _requestOwnerAccessOnSignUp = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF0F766E),
            title: Text(
              l10n.ownerSignUpOption,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            l10n.ownerSignUpHint,
            style: TextStyle(
              color: isDark ? const Color(0xFFD6E4FF) : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (_requestOwnerAccessOnSignUp) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: ownerCenterNameController,
              label: l10n.ownerApplicationCenterName,
              icon: Icons.storefront_outlined,
              focusNode: _ownerCenterNameFocusNode,
              nextFocus: _ownerPhoneFocusNode,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: ownerPhoneController,
              label: l10n.ownerApplicationPhone,
              icon: Icons.call_outlined,
              focusNode: _ownerPhoneFocusNode,
              nextFocus: _ownerAddressFocusNode,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: ownerAddressController,
              label: l10n.ownerApplicationAddress,
              icon: Icons.location_on_outlined,
              focusNode: _ownerAddressFocusNode,
              nextFocus: _ownerLinkFocusNode,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: ownerLinkController,
              label: l10n.ownerApplicationLink,
              icon: Icons.link_outlined,
              focusNode: _ownerLinkFocusNode,
              nextFocus: _ownerNoteFocusNode,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: ownerNoteController,
              label: l10n.ownerApplicationNote,
              icon: Icons.notes_outlined,
              focusNode: _ownerNoteFocusNode,
              maxLines: 3,
              onDone: _submitAuth,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Stack(
      children: [
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF081120).withValues(alpha: 0.66)
                                    : Colors.white.withValues(alpha: 0.92),
                                border: Border.all(
                                  color: (isDark
                                          ? const Color(0xFF67E8F9)
                                          : const Color(0xFF14B8A6))
                                      .withValues(alpha: 0.55),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? const Color(0xFF67E8F9)
                                            : const Color(0xFF14B8A6))
                                        .withValues(alpha: 0.16),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: isDark
                                    ? const Color(0xFF67E8F9)
                                    : const Color(0xFF0F766E),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _isSignUp ? l10n.signUp : l10n.signIn,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                                shadows: isDark
                                    ? const [
                                  Shadow(
                                    color: Color(0xCC020617),
                                    blurRadius: 14,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildField(
                              controller: emailController,
                              label: l10n.email,
                              icon: Icons.person_outline_rounded,
                              focusNode: _emailFocusNode,
                              nextFocus: _passwordFocusNode,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: passwordController,
                              label: l10n.password,
                              icon: Icons.key_outlined,
                              focusNode: _passwordFocusNode,
                              nextFocus: _isSignUp ? _confirmPasswordFocusNode : null,
                              obscureText: true,
                              onDone: _submitAuth,
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 14),
                              _buildField(
                                controller: confirmPasswordController,
                                label: l10n.confirmPassword,
                                icon: Icons.verified_user_outlined,
                                focusNode: _confirmPasswordFocusNode,
                                nextFocus: _requestOwnerAccessOnSignUp
                                    ? _ownerCenterNameFocusNode
                                    : null,
                                obscureText: true,
                                onDone: _submitAuth,
                              ),
                              const SizedBox(height: 14),
                              _buildOwnerRequestFields(l10n),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFF14B8A6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: isDark
                                      ? const Color(0xFF67E8F9)
                                      : const Color(0xFF14B8A6),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? l10n.signUp : l10n.signIn,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isSignUp = !_isSignUp;
                                        if (!_isSignUp) {
                                          _requestOwnerAccessOnSignUp = false;
                                        }
                                      });
                                    },
                              child: Text(
                                _isSignUp
                                    ? l10n.switchToSignIn
                                    : l10n.switchToSignUp,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFE9D5FF)
                                      : const Color(0xFF0F766E),
                                  fontWeight: FontWeight.w700,
                                  shadows: isDark
                                      ? const [
                                    Shadow(
                                      color: Color(0xCC020617),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: SafeArea(child: AppHeaderActions()),
        ),
      ],
    );

    return Scaffold(
      body: content,
    );
  }
}
