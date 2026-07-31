import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_navigator.dart';
import 'core/app_theme.dart';
import 'core/i18n/locale_controller.dart';
import 'core/supabase_config.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/role_onboarding_screen.dart';
import 'features/dashboard/patient/patient_home_shell.dart';
import 'features/family/family_home_shell.dart';
import 'features/volunteer/volunteer_home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const CareBridgeApp());
}

/// Root widget for the BridgeCare Flutter app.
class CareBridgeApp extends StatefulWidget {
  const CareBridgeApp({super.key});

  @override
  State<CareBridgeApp> createState() => _CareBridgeAppState();
}

class _CareBridgeAppState extends State<CareBridgeApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // When Supabase fires `passwordRecovery` (the user just opened the link
    // from their reset email and the SDK exchanged it for a session), navigate
    // to the new-password screen. The `processRecoveryUrl` path also calls
    // `goToResetPasswordOnce` directly as a belt-and-braces safety net.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        goToResetPasswordOnce();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => MaterialApp(
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'BridgeCare',
        theme: AppTheme.light(),
        locale: LocaleController.instance.locale,
        supportedLocales: const [Locale('en'), Locale('sq')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/signup': (context) => const SignupScreen(),
          '/login': (context) => const LoginScreen(),
          '/role_onboarding': (context) => const RoleOnboardingScreen(),
          '/home_user': (context) => const PatientHomeShell(),
          '/home_family': (context) => const FamilyHomeShell(),
          '/home_volunteer': (context) => const VolunteerHomeShell(),
          '/home_admin': (context) =>
              const _HomePlaceholder(title: 'Admin Home'),
        },
      ),
    );
  }
}

/// Placeholder routes for non–user-side roles. User/elderly work is in
/// [PatientHomeShell] at `/home_user`.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title is connected.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
