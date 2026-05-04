import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/booking_store.dart';
import 'data/center_store.dart';
import 'data/firebase_state.dart';
import 'data/role_store.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'screens/admin_root_shell.dart';
import 'screens/login_screen.dart';
import 'screens/owner_pending_screen.dart';
import 'screens/owner_root_shell.dart';
import 'screens/root_shell.dart';
import 'widgets/app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    firebaseAvailable = true;
  } catch (_) {
    firebaseAvailable = false;
  }
  await BookingStore.initialize();
  await CenterStore.initialize();
  await RoleStore.initialize();
  await themeController.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, themeMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              builder: (context, child) {
                return AppBackground(child: child ?? const SizedBox.shrink());
              },
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF15B8A6),
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: Colors.white.withValues(alpha: 0.92),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        indicatorColor: const Color(0xFF15B8A6).withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? const Color(0xFF0F766E)
                : const Color(0xFF475569),
          );
        }),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF15B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.96),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF15B8A6),
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: const Color(0xCC101826),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0C1424).withValues(alpha: 0.86),
        indicatorColor: const Color(0xFF15B8A6).withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? const Color(0xFF67E8F9) : Colors.white70,
          );
        }),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF111827)),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF15B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xCC101826),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xCC172033),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool _isWaitingForAuth = true;

  @override
  void initState() {
    super.initState();
    if (!firebaseAvailable) {
      _isWaitingForAuth = false;
      return;
    }
    _user = FirebaseAuth.instance.currentUser;
    _isWaitingForAuth = false;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      final currentUid = _user?.uid;
      final nextUid = user?.uid;
      if (currentUid == nextUid) return;
      setState(() {
        _user = user;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseAvailable) {
      return const RootShell();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: authFlowInProgress,
      builder: (context, isAuthFlowInProgress, _) {
        if (_isWaitingForAuth || isAuthFlowInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = _user;
        if (user == null) return const LoginScreen();
        return ValueListenableBuilder<int>(
          valueListenable: RoleStore.rolesRevision,
          builder: (context, revision, _) =>
              RoleGate(email: user.email, revision: revision),
        );
      },
    );
  }
}

class RoleGate extends StatefulWidget {
  const RoleGate({super.key, required this.email, required this.revision});

  final String? email;
  final int revision;

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  String? _role;
  Object? _loadToken;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void didUpdateWidget(covariant RoleGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email ||
        oldWidget.revision != widget.revision) {
      _loadRole();
    }
  }

  Future<void> _loadRole() async {
    final token = Object();
    _loadToken = token;
    final role = await RoleStore.roleForEmail(widget.email);
    if (!mounted || _loadToken != token) return;
    if (_role == role) return;
    setState(() {
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (role == RoleStore.ownerPendingRole) {
      return const OwnerPendingScreen();
    }
    if (role == RoleStore.adminRole) {
      return const AdminRootShell();
    }
    if (role == RoleStore.ownerRole) {
      return const OwnerRootShell();
    }
    return const RootShell();
  }
}
