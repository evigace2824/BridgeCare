import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gotrue/gotrue.dart' as gt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_navigator.dart';
import '../core/password_policy.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';
import 'oauth_redirect_server.dart';
import 'signup_verification_service.dart';

/// **App-specific** error type for auth flows (thrown to UI as [AuthException.message]).
///
/// GoTrue/Supabase throws their own [gt.AuthException]; this class wraps messages into
/// one type the screens catch consistently.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result of [AuthService.signUp].
///
/// Distinguishes the three real cases so the UI can show the right screen:
/// - [autoSignedIn]: project has email confirmation OFF, user is already in.
/// - [needsEmailConfirmation]: brand-new account, must click the link.
/// - [alreadyRegisteredUnconfirmed]: email was previously used; we attempted a
///   silent resend so the user just needs to open the link in their inbox.
/// - [alreadyRegisteredConfirmed]: account exists and is fully usable — user
///   should sign in instead.
enum SignUpOutcome {
  autoSignedIn,
  needsEmailConfirmation,
  alreadyRegisteredUnconfirmed,
  alreadyRegisteredConfirmed,
}

/// **Single gateway** between BridgeCare and Supabase: **Auth** (`auth.users` session)
/// plus **`public.users`** profile data (and related tables).
///
/// **Design**
/// - **Singleton** [instance]: every screen uses the same service (no duplicate clients).
/// - **Two layers:** (1) Supabase Auth API — passwords, OAuth PKCE, sessions;
///   (2) PostgREST — `users`, `volunteer_profiles`, `contacts`.
/// - **Screens stay thin:** they call methods here; this file owns validation side-effects,
///   error translation, and when to upsert rows.
///
/// **Main responsibilities**
/// - [signIn] / [signUp] / [signInWithGoogle] / [signOut]
/// - Load [UserModel] via [getCurrentUserProfile]; create missing rows after OAuth
///   ([_tryEnsureUserRowFromAuthSession])
/// - Desktop OAuth loopback ([_signInWithOAuthDesktopLoopback] + [oauth_redirect_server])
/// - Post–sign-up side effects ([_persistSignupSideEffects])
/// - First-time OAuth role step ([completeRoleOnboarding])
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Shortcut to the initialized Supabase client from `main.dart`.
  SupabaseClient get _client => Supabase.instance.client;

  /// Currently signed-in user's UUID from the session, or `null` if logged out.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// **Desktop (Windows/macOS/Linux):** OAuth must return to `http://127.0.0.1:port/`
  /// because custom URL schemes are not registered like on mobile.
  bool get _useDesktopLoopbackOAuth =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Optional query params forwarded to Google's OAuth URL (`prompt=select_account`
  /// lets the user pick which Google account in the browser).
  static Map<String, String>? _googleOAuthQueryParams(OAuthProvider provider) {
    if (provider != OAuthProvider.google) return null;
    return const {'prompt': 'select_account'};
  }

  // ---------------------------------------------------------------------------
  // Sign in: Auth session + load `users` row (and joined volunteer_profiles)
  // ---------------------------------------------------------------------------

  /// **Email + password sign-in.**
  ///
  /// 1. Calls Supabase `signInWithPassword` (GoTrue validates credentials).
  /// 2. Loads `public.users` (+ nested volunteer row) via [getCurrentUserProfile].
  /// 3. If no row exists, tries [_tryEnsureUserRowFromAuthSession] (RLS must allow it).
  /// 4. On failure after auth succeeded, **signs out** so the app is not half-logged-in.
  ///
  /// Returns a [UserModel] the UI uses for [UserModel.postAuthRoute].
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) throw AuthException('Please enter your email.');
    if (password.isEmpty) throw AuthException('Please enter your password.');

    try {
      final res = await _client.auth.signInWithPassword(
        email: trimmed,
        password: password,
      );
      if (res.user == null) {
        throw AuthException('Sign in failed. Please try again.');
      }
    } on gt.AuthException catch (e) {
      throw AuthException(_signInAuthMessage(e));
    }

    var profile = await getCurrentUserProfile();
    profile ??= await _tryEnsureUserRowFromAuthSession();
    if (profile == null) {
      await _client.auth.signOut();
      throw AuthException(
        'Signed in with Supabase, but there is no row in public.users and the app '
        'could not create one. Fix: add RLS INSERT/UPDATE for auth.uid() on public.users, '
        'or insert a row where id equals your Auth user id. '
        'Note: rows only in public.users (not in Authentication → Users) cannot log in.',
      );
    }
    return profile;
  }

  /// Turns raw GoTrue [gt.AuthException] messages/codes into user-facing strings
  /// (e.g. email not confirmed vs invalid password vs missing auth user).
  String _signInAuthMessage(gt.AuthException e) {
    final code = e.code?.toLowerCase();
    if (code == 'user_not_found') {
      return 'No password account for this email. Create the user under '
          'Supabase → Authentication → Users, or sign up in the app.';
    }
    if (code == 'email_not_confirmed') {
      return 'Confirm your email first—open the link Supabase sent you, then sign in.';
    }
    final m = e.message.toLowerCase();
    if (m.contains('email') && m.contains('confirm')) {
      return 'Confirm your email first—open the link Supabase sent you, then sign in.';
    }
    if (m.contains('invalid') && m.contains('credential')) {
      return 'Invalid email or password. Password accounts must exist under '
          'Supabase Dashboard → Authentication → Users (not only Table Editor → users).';
    }
    return e.message;
  }

  // ---------------------------------------------------------------------------
  // OAuth (Google) — enable provider in Supabase → Authentication
  // ---------------------------------------------------------------------------

  /// Starts Google OAuth (delegates to [signInWithOAuth]).
  Future<UserModel> signInWithGoogle() => signInWithOAuth(OAuthProvider.google);

  /// **OAuth for mobile / web** (not desktop loopback).
  ///
  /// 1. Subscribes to `onAuthStateChange` and waits for `signedIn` with a session
  ///    after the browser / deep link completes (PKCE code exchange happens inside SDK).
  /// 2. Opens the provider URL via `url_launcher` ([LaunchMode.externalApplication] for Google).
  /// 3. Loads or creates [UserModel] like [signIn].
  Future<UserModel> signInWithOAuth(OAuthProvider provider) async {
    if (_useDesktopLoopbackOAuth) {
      return _signInWithOAuthDesktopLoopback(provider);
    }

    final redirectTo = SupabaseConfig.oauthRedirectUri;

    final completer = Completer<Session>();
    var acceptAuthEvents = false;

    late final StreamSubscription<AuthState> sub;
    sub = _client.auth.onAuthStateChange.listen((data) {
      if (!acceptAuthEvents) return;
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        if (!completer.isCompleted) {
          completer.complete(data.session!);
        }
      }
    });

    try {
      final opened = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
        authScreenLaunchMode: provider == OAuthProvider.google
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
        queryParams: _googleOAuthQueryParams(provider),
      );
      if (!opened) {
        throw AuthException('Could not open the sign-in page.');
      }
      acceptAuthEvents = true;

      await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw AuthException(
            'Sign-in timed out. Complete the steps in the browser, then return '
            'to the app.',
          );
        },
      );
    } on AuthException {
      rethrow;
    } on gt.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('OAuth sign-in failed: $e');
    } finally {
      await sub.cancel();
    }

    var profile = await getCurrentUserProfile();
    profile ??= await _tryEnsureUserRowFromAuthSession();
    if (profile == null) {
      await _client.auth.signOut();
      throw AuthException(
        'No profile in public.users and auto-create failed. Check RLS on public.users '
        'or add a trigger from auth.users.',
      );
    }
    return profile;
  }

  /// **Desktop OAuth:** local HTTP server receives `?code=` from the browser, then
  /// [getSessionFromUrl] exchanges the PKCE code for a session.
  ///
  /// [captureOAuthRedirectOnce] binds the port **before** opening the browser so the
  /// callback is never missed. Redirect URL must be listed in Supabase **and** Google
  /// must use Supabase's `/auth/v1/callback` (not localhost) on the Google Cloud client.
  Future<UserModel> _signInWithOAuthDesktopLoopback(
    OAuthProvider provider,
  ) async {
    final redirectTo = SupabaseConfig.oauthDesktopRedirectUri;
    final port = SupabaseConfig.oauthDesktopPort;

    final callbackUri = await captureOAuthRedirectOnce(
      port: port,
      ipv6Loopback: SupabaseConfig.oauthDesktopUseLocalhost,
      afterServerListening: () async {
        final oauth = await _client.auth.getOAuthSignInUrl(
          provider: provider,
          redirectTo: redirectTo,
          queryParams: _googleOAuthQueryParams(provider),
        );
        final launched = await launchUrl(
          Uri.parse(oauth.url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw AuthException('Could not open the sign-in page.');
        }
      },
    );

    if (callbackUri == null) {
      final alt = SupabaseConfig.oauthDesktopUseLocalhost
          ? 'http://127.0.0.1:$port/'
          : 'http://localhost:$port/';
      throw AuthException(
        'Google sign-in did not return to the app (timeout). Checklist:\n'
        '1) Supabase → Authentication → URL Configuration → Redirect URLs: add '
        'EXACTLY: $redirectTo and also $alt\n'
        '2) Enable Google under Authentication → Sign In / Providers.\n'
        '3) Google Cloud → OAuth client → Authorized redirect URIs: only your '
        'Supabase URL …/auth/v1/callback (NOT localhost).\n'
        '4) If Windows Firewall asked about Dart, click Allow.\n'
        '5) If it still times out, run: flutter run -d windows '
        '--dart-define=OAUTH_DESKTOP_LOCALHOST=true (or false to switch back).',
      );
    }

    try {
      await _client.auth.getSessionFromUrl(callbackUri);
    } on gt.AuthException catch (e) {
      throw AuthException(e.message);
    }

    var profile = await getCurrentUserProfile();
    profile ??= await _tryEnsureUserRowFromAuthSession();

    if (profile == null) {
      await _client.auth.signOut();
      throw AuthException(
        'No profile in public.users and auto-create failed. Check RLS on public.users.',
      );
    }
    return profile;
  }

  /// **Auto-heal missing profile row** after login/OAuth.
  ///
  /// Supabase Auth can succeed while `public.users` has no row yet. This builds a minimal
  /// upsert from JWT [user.userMetadata] (name, role, phone) and falls back to role
  /// `elderly` with [isProfileComplete] `false` so [UserModel.postAuthRoute] sends the user
  /// to role onboarding. Tries several column subsets if the table schema differs.
  ///
  /// Requires RLS policies that allow the authenticated user to insert/update their own `id`.
  Future<UserModel?> _tryEnsureUserRowFromAuthSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final meta = user.userMetadata ?? {};
    final rawName = meta['full_name'] ??
        meta['name'] ??
        meta['given_name'] ??
        meta['preferred_username'];
    final name = rawName is String ? rawName : rawName?.toString();
    final roleRaw = _roleStringForDb(meta['role']);
    final phone = meta['phone'] as String? ?? meta['phone_number'] as String?;
    final email = user.email ?? '';

    final attempts = <Map<String, dynamic>>[
      {
        'id': user.id,
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        'role': roleRaw,
        if (phone != null && phone.isNotEmpty) 'phone_number': phone,
        'is_profile_complete': false,
      },
      {
        'id': user.id,
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        'role': roleRaw,
        'is_profile_complete': false,
      },
      {
        'id': user.id,
        'email': email,
        'role': roleRaw,
        'is_profile_complete': false,
      },
      {
        'id': user.id,
        'role': 'elderly',
        'is_profile_complete': false,
      },
    ];

    for (final raw in attempts) {
      final row = Map<String, dynamic>.from(raw)
        ..removeWhere(
          (_, v) => v == null || (v is String && v.isEmpty),
        );
      try {
        await _client.from('users').upsert(row, onConflict: 'id');
        final loaded = await getCurrentUserProfile();
        if (loaded != null) return loaded;
      } on PostgrestException catch (e) {
        debugPrint('users upsert (session ensure): ${e.message}');
      }
    }
    return null;
  }

  /// Normalizes metadata role strings to allowed DB enum values; unknown → `elderly`.
  static String _roleStringForDb(dynamic raw) {
    final s = raw?.toString().toLowerCase().trim() ?? '';
    const allowed = {'elderly', 'family', 'volunteer', 'admin'};
    if (allowed.contains(s)) return s;
    return 'elderly';
  }

  // ---------------------------------------------------------------------------
  // Sign up: Auth + metadata for trigger; optional immediate row updates
  // ---------------------------------------------------------------------------

  /// **Registers** a new email/password account and stores rich metadata for triggers / app.
  ///
  /// - Validates password via [PasswordPolicy].
  /// - `auth.signUp` stores `full_name`, `role`, `phone`, and JSON `signup_extras` in user metadata.
  /// - If Supabase returns a **session** (email confirmation off), upserts `public.users`
  ///   with [isProfileComplete] `true` and runs [_persistSignupSideEffects] (volunteer row,
  ///   emergency contact, etc.).
  /// - Detects Supabase's "fake success" response for already-registered emails
  ///   (`identities` empty + no session) and auto-resends the confirmation link,
  ///   so first-time and retry signups behave the same way for the user.
  /// - Returns a [SignUpOutcome] the UI uses to decide which screen to show.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String phoneNumber,
    List<String> conditions = const [],
    bool takesMedication = false,
    List<String> medications = const [],
    List<String?> medicationReminderTimes = const [],
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    String emergencyRelation = '',
    List<int> availableDays = const [],
    String? availableFrom,
    String? availableTo,
    List<String> skills = const [],
    String transport = 'None',
    String familyVerificationCode = '',
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) throw AuthException('Please enter your email.');
    final pwError = PasswordPolicy.validate(password);
    if (pwError != null) throw AuthException(pwError);

    final extras = <String, dynamic>{
      'conditions': conditions,
      'takes_medication': takesMedication,
      'medications': <Map<String, dynamic>>[
        for (var i = 0; i < medications.length; i++)
          {
            'name': medications[i],
            if (i < medicationReminderTimes.length &&
                medicationReminderTimes[i] != null &&
                medicationReminderTimes[i]!.isNotEmpty)
              'reminder_time': medicationReminderTimes[i],
          },
      ],
      'emergency': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
        'relation': emergencyRelation,
      },
      'volunteer': {
        'available_days': availableDays,
        'available_from': availableFrom,
        'available_to': availableTo,
        'skills': skills,
        'transport': transport,
      },
      'family': {'verification_code': familyVerificationCode},
    };

    try {
      final redirectTo = SupabaseConfig.siteUrl.isNotEmpty
          ? SupabaseConfig.siteUrl
          : null;
      final response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        emailRedirectTo: redirectTo,
        data: {
          'full_name': fullName,
          'role': role.name,
          'phone': phoneNumber,
          'signup_extras': jsonEncode(extras),
        },
      );

      final user = response.user;
      if (user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      // When a session exists (e.g. email confirmation off), persist related rows.
      if (response.session != null) {
        await _ensurePublicUserRowAfterSignup(
          userId: user.id,
          email: trimmedEmail,
          fullName: fullName,
          role: role,
          phoneNumber: phoneNumber,
        );
        await _persistSignupSideEffects(
          userId: user.id,
          fullName: fullName,
          role: role,
          phoneNumber: phoneNumber,
          skills: skills,
          transport: transport,
          availableDays: availableDays,
          availableFrom: availableFrom,
          availableTo: availableTo,
          familyVerificationCode: familyVerificationCode,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
          emergencyRelation: emergencyRelation,
        );
        return SignUpOutcome.autoSignedIn;
      }

      // No session means email confirmation is required. Detect the
      // already-registered case: Supabase returns a fake user with empty
      // `identities` for security. In that case auto-trigger a resend so
      // the user can complete the original confirmation.
      final identities = user.identities ?? const <gt.UserIdentity>[];
      final alreadyRegistered = identities.isEmpty;

      if (alreadyRegistered) {
        try {
          await _client.auth.resend(
            type: gt.OtpType.signup,
            email: trimmedEmail,
            emailRedirectTo: redirectTo,
          );
          return SignUpOutcome.alreadyRegisteredUnconfirmed;
        } on gt.AuthException catch (e) {
          // Common case: account is already confirmed → resend rejects.
          final m = e.message.toLowerCase();
          if (m.contains('confirmed') || m.contains('already')) {
            return SignUpOutcome.alreadyRegisteredConfirmed;
          }
          // Rate limit, etc.: surface the message but keep the user on the
          // verify screen so they can manually retry after a cooldown.
          debugPrint('signUp resend (already-registered): ${e.message}');
          return SignUpOutcome.alreadyRegisteredUnconfirmed;
        } catch (e) {
          debugPrint('signUp resend (already-registered): $e');
          return SignUpOutcome.alreadyRegisteredUnconfirmed;
        }
      }

      try {
        await SignupVerificationService.instance.sendSignupVerification(
          email: trimmedEmail,
        );
      } catch (e) {
        debugPrint('signUp: could not send verification email: $e');
      }
      return SignUpOutcome.needsEmailConfirmation;
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      final message = _normalizedAuthErrorMessage(e.message);
      if (_isSignupEmailSendFailure(message)) {
        final recovered = await _recoverFromSignupEmailSendFailure(
          email: trimmedEmail,
          password: password,
        );
        if (recovered != null) return recovered;
        throw AuthException(
          'The account may have been created, but confirmation email sending '
          'failed on the server. Check Supabase Auth email settings (SMTP / '
          'provider), then tap Sign Up again or use Resend on the verify screen.',
        );
      }
      throw AuthException(message);
    } on gt.AuthException catch (e) {
      final message = _normalizedAuthErrorMessage(e.message);
      if (_isSignupEmailSendFailure(message)) {
        final recovered = await _recoverFromSignupEmailSendFailure(
          email: trimmedEmail,
          password: password,
        );
        if (recovered != null) return recovered;
      }
      throw AuthException(message);
    } on PostgrestException catch (e) {
      throw AuthException(e.message);
    } catch (e, st) {
      debugPrint('signUp: $e\n$st');
      throw AuthException(
        kDebugMode
            ? e.toString()
            : 'Something went wrong. Please try again.',
      );
    }
  }

  bool _isSignupEmailSendFailure(String message) {
    final blob = message.toLowerCase();
    return blob.contains('error sending confirmation email') ||
        blob.contains('unexpected_failure');
  }

  String _normalizedAuthErrorMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } catch (_) {}
    }
    return raw;
  }

  Future<SignUpOutcome?> _recoverFromSignupEmailSendFailure({
    required String email,
    required String password,
  }) async {
    final redirectTo = SupabaseConfig.siteUrl.isNotEmpty
        ? SupabaseConfig.siteUrl
        : null;

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirectTo,
      );
      return SignUpOutcome.needsEmailConfirmation;
    } catch (_) {}

    try {
      await SignupVerificationService.instance.sendSignupVerification(email: email);
      return SignUpOutcome.needsEmailConfirmation;
    } catch (_) {}

    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await _client.auth.signOut();
        return SignUpOutcome.autoSignedIn;
      }
    } on gt.AuthException catch (e) {
      final m = e.message.toLowerCase();
      final code = e.code?.toLowerCase();
      if (code == 'email_not_confirmed' ||
          (m.contains('email') && m.contains('confirm'))) {
        return SignUpOutcome.needsEmailConfirmation;
      }
    } catch (_) {}

    return null;
  }

  /// Upserts `public.users` right after signup when a session exists; marks profile complete
  /// because the multi-step signup form already collected role and details. Retries with
  /// fewer columns if PostgREST rejects unknown fields.
  Future<void> _ensurePublicUserRowAfterSignup({
    required String userId,
    required String email,
    required String fullName,
    required UserRole role,
    required String phoneNumber,
  }) async {
    final familyCode = role == UserRole.elderly ? _generateFamilyLinkCode() : null;

    final attempts = <Map<String, dynamic>>[
      {
        'id': userId,
        'email': email,
        'name': fullName,
        'role': role.name,
        'phone_number': phoneNumber.isEmpty ? null : phoneNumber,
        'is_profile_complete': true,
        if (familyCode != null) 'family_verification_code': familyCode,
      },
      {
        'id': userId,
        'email': email,
        'name': fullName,
        'role': role.name,
        'is_profile_complete': true,
      },
      {
        'id': userId,
        'name': fullName,
        'role': role.name,
        'is_profile_complete': true,
      },
    ];

    for (final raw in attempts) {
      final row = Map<String, dynamic>.from(raw)
        ..removeWhere((_, v) => v == null);
      try {
        await _client.from('users').upsert(row, onConflict: 'id');
        return;
      } on PostgrestException catch (e) {
        debugPrint('users upsert: ${e.message}');
      }
    }
  }

  /// **Extra tables** after the core `users` row: patch phone/family code, upsert
  /// `volunteer_profiles` for volunteers, insert `contacts` for elderly with emergency data.
  /// Errors are logged only so a partial failure does not block account creation.
  Future<void> _persistSignupSideEffects({
    required String userId,
    required String fullName,
    required UserRole role,
    required String phoneNumber,
    required List<String> skills,
    required String transport,
    required List<int> availableDays,
    String? availableFrom,
    String? availableTo,
    required String familyVerificationCode,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyRelation,
  }) async {
    try {
      final userPatch = <String, dynamic>{
        'phone_number': phoneNumber,
        if (familyVerificationCode.isNotEmpty)
          'family_verification_code': familyVerificationCode,
      }..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

      if (userPatch.isNotEmpty) {
        await _client.from('users').update(userPatch).eq('id', userId);
      }

      if (role == UserRole.family && familyVerificationCode.trim().isNotEmpty) {
        try {
          await _client.rpc(
            'link_family_to_patient',
            params: {'link_code': familyVerificationCode.trim()},
          );
        } catch (e) {
          debugPrint('link_family_to_patient after signup: $e');
        }
      }

      if (role == UserRole.volunteer) {
        final availability = _formatVolunteerAvailability(
          availableDays,
          availableFrom,
          availableTo,
        );
        await _client.from('volunteer_profiles').upsert(
          {
            'user_id': userId,
            'skills': skills.isEmpty ? null : skills.join(', '),
            'availability': availability,
            'transport': transport,
          },
          onConflict: 'user_id',
        );
      }

      if (role == UserRole.elderly &&
          emergencyContactName.isNotEmpty &&
          emergencyContactPhone.isNotEmpty) {
        await addEmergencyContact(
          contactName: emergencyContactName,
          phone: emergencyContactPhone,
          relationship: emergencyRelation,
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('Post-signup side effects: ${e.message}');
    }
  }

  /// Serializes volunteer availability days + optional time window into one text field.
  String _formatVolunteerAvailability(
    List<int> days,
    String? from,
    String? to,
  ) {
    if (days.isEmpty && from == null && to == null) return '';
    final dayPart = days.isEmpty ? '' : 'days:${days.join(',')}';
    final timePart = [
      if (from != null && from.isNotEmpty) 'from:$from',
      if (to != null && to.isNotEmpty) 'to:$to',
    ].join('|');
    return [dayPart, timePart].where((s) => s.isNotEmpty).join(' ');
  }

  // ---------------------------------------------------------------------------
  // Profile load / update
  // ---------------------------------------------------------------------------

  /// Reads the current auth user's row from `users` with `volunteer_profiles(*)` join
  /// and maps it to [UserModel]. Returns `null` if no row, RLS denies, or query errors.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('users')
          .select('*, volunteer_profiles(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      final map = Map<String, dynamic>.from(data);
      map.putIfAbsent('email', () => user.email);
      return UserModel.fromMap(map);
    } catch (e, st) {
      debugPrint('getCurrentUserProfile: $e\n$st');
      return null;
    }
  }

  /// **First-time OAuth onboarding:** updates `role`, optional `name`, sets
  /// `is_profile_complete` true, then reloads [UserModel] for navigation to [UserModel.homeRoute].
  Future<UserModel> completeRoleOnboarding({
    required UserRole role,
    String? displayName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('Not signed in.');

    final patch = <String, dynamic>{
      'role': role.name,
      'is_profile_complete': true,
    };
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      patch['name'] = trimmed;
    }

    try {
      await _client.from('users').update(patch).eq('id', user.id);
    } on PostgrestException catch (e) {
      throw AuthException(e.message);
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw AuthException('Could not load your profile after update.');
    }
    return profile;
  }

  /// Persists edits from a full [UserModel] (settings-style): updates `users` and
  /// volunteer profile when applicable.
  Future<void> completeProfile(UserModel user) async {
    try {
      final patch = user.toUserTableMap()
        ..removeWhere((_, v) => v == null);
      if (patch.isNotEmpty) {
        await _client.from('users').update(patch).eq('id', user.id);
      }

      if (user.role == UserRole.volunteer) {
        final vMap = user.toVolunteerProfileMap()
          ..removeWhere((_, v) => v == null);
        await _client.from('volunteer_profiles').upsert(
              vMap,
              onConflict: 'user_id',
            );
      }
    } on PostgrestException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Inserts one row into `contacts` for the signed-in user (elderly signup path).
  Future<void> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('contacts').insert({
      'user_id': user.id,
      'contact_name': contactName,
      'phone': phone,
      'relationship': relationship,
    });
  }

  /// Requests an SMS OTP via Supabase Auth for the provided phone number.
  ///
  /// Requires SMS provider configuration in Supabase Authentication settings.
  Future<void> requestPhoneOtp({required String phoneNumber}) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      throw AuthException('Please enter your phone number.');
    }
    try {
      await _client.auth.signInWithOtp(phone: trimmed);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } on gt.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Could not send verification code: $e');
    }
  }

  /// Verifies an SMS OTP sent by Supabase for the given phone number.
  ///
  /// Returns the session user id when verification succeeds.
  Future<String> verifyPhoneOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    final trimmedCode = code.trim();

    if (trimmedPhone.isEmpty) {
      throw AuthException('Missing phone number.');
    }
    if (trimmedCode.length != 6) {
      throw AuthException('Please enter the 6-digit verification code.');
    }

    try {
      final response = await _client.auth.verifyOTP(
        phone: trimmedPhone,
        token: trimmedCode,
        type: OtpType.sms,
      );
      final userId = response.user?.id;
      if (userId == null || userId.isEmpty) {
        throw AuthException('Verification failed. Please request a new code.');
      }
      return userId;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } on gt.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Could not verify the code: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset (forgot password flow)
  // ---------------------------------------------------------------------------

  /// **Sends a password-recovery email** for [email].
  ///
  /// Supabase delivers an email containing a link with a `recovery` token.
  /// When the user clicks it, the app receives `AuthChangeEvent.passwordRecovery`
  /// (handled globally in `main.dart`) and routes to `ResetPasswordScreen`.
  ///
  /// `redirectTo` is set so links land back in the app on mobile / desktop
  /// loopback, matching the OAuth redirect URL configuration.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw AuthException('Please enter your email.');
    }
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
      throw AuthException('Please enter a valid email address.');
    }
    try {
      await _client.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: _passwordRecoveryRedirectUrl(),
      );
    } on gt.AuthException catch (e) {
      throw AuthException(_resendAuthMessage(e));
    } catch (_) {
      throw AuthException(
        'Could not send the reset email. Check your connection and try again.',
      );
    }
  }

  /// Picks the best `redirectTo` for password recovery based on platform.
  /// Reuses the OAuth redirect URLs already configured in Supabase.
  String? _passwordRecoveryRedirectUrl() {
    if (kIsWeb) {
      if (SupabaseConfig.siteUrl.isNotEmpty) return SupabaseConfig.siteUrl;
      try {
        return Uri.base.origin;
      } catch (_) {
        return null;
      }
    }
    if (_useDesktopLoopbackOAuth) {
      return SupabaseConfig.oauthDesktopRedirectUri;
    }
    return SupabaseConfig.oauthRedirectUri;
  }

  /// Hands a recovery callback URL (from the email link) to Supabase so the
  /// SDK can mint a short-lived session and emit `passwordRecovery` — which
  /// the global listener in `main.dart` reacts to by pushing the new-password
  /// screen.
  ///
  /// Accepts either the full URL string or a parsed [Uri]. Used by both the
  /// **desktop loopback listener** (automatic capture) and the **manual paste**
  /// fallback on the Forgot Password screen.
  Future<void> processRecoveryUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw AuthException('Please paste the link from your email.');
    }

    Uri parsed;
    try {
      parsed = Uri.parse(trimmed);
    } catch (_) {
      throw AuthException('That does not look like a valid link.');
    }

    if (!_looksLikeRecoveryUri(parsed)) {
      throw AuthException(
        'This link is not a password reset link. Open the email titled '
        '"Reset Your Password" and copy the link inside.',
      );
    }

    try {
      await _client.auth.getSessionFromUrl(parsed);
    } on gt.AuthException catch (e) {
      throw AuthException(_recoveryUrlMessage(e));
    } catch (_) {
      throw AuthException(
        'Could not use this link. It may have expired — request a new one.',
      );
    }

    // Belt-and-braces: navigate explicitly. The `passwordRecovery` event in
    // `main.dart` also calls this same de-duped helper, so whichever fires
    // first wins and the second is a no-op.
    goToResetPasswordOnce();
  }

  /// Heuristic for "this URL is a Supabase recovery callback" — covers query
  /// params (`?code=...`) and fragments (`#access_token=...&type=recovery`).
  bool _looksLikeRecoveryUri(Uri uri) {
    bool hit(Map<String, String> map) =>
        map.containsKey('code') ||
        map.containsKey('access_token') ||
        map['type'] == 'recovery' ||
        map.containsKey('error');

    if (hit(uri.queryParameters)) return true;
    if (uri.fragment.isNotEmpty &&
        hit(Uri.splitQueryString(uri.fragment))) {
      return true;
    }
    return false;
  }

  String _recoveryUrlMessage(gt.AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('expired') || m.contains('invalid')) {
      return 'This reset link has expired or was already used. Request a new one.';
    }
    return e.message;
  }

  /// Starts a desktop loopback HTTP server on the OAuth recovery port and
  /// forwards any captured recovery URL through [processRecoveryUrl].
  ///
  /// Returns a handle the caller (typically `ForgotPasswordScreen`) closes
  /// when leaving the screen. Returns `null` on web / when the port is busy
  /// — UI should fall back to the manual-paste affordance.
  Future<LoopbackAuthCallbackServer?> startDesktopRecoveryListener({
    void Function(Object error)? onError,
  }) async {
    if (kIsWeb || !_useDesktopLoopbackOAuth) return null;
    return LoopbackAuthCallbackServer.start(
      port: SupabaseConfig.oauthDesktopPort,
      ipv6Loopback: SupabaseConfig.oauthDesktopUseLocalhost,
      onCallback: (uri) async {
        try {
          await processRecoveryUrl(uri.toString());
        } catch (e) {
          if (onError != null) onError(e);
          debugPrint('Desktop recovery listener: $e');
        }
      },
    );
  }

  /// **Updates the password** of the currently signed-in user (typically the
  /// short-lived recovery session created when the user clicks the email link).
  ///
  /// Validates the new password through [PasswordPolicy] before sending.
  Future<void> updatePassword({required String newPassword}) async {
    final pwError = PasswordPolicy.validate(newPassword);
    if (pwError != null) throw AuthException(pwError);

    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Recovery session expired. Open the link in your email again.',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on gt.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw AuthException('Could not update your password. Please try again.');
    }
  }

  /// Re-sends the signup verification email for an existing unconfirmed account.
  ///
  /// Translates the most common Supabase responses (rate limit, already
  /// confirmed, unknown user) into copy the UI can show directly.
  Future<void> resendSignupVerificationEmail({required String email}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw AuthException('Please enter your email first.');
    }
    try {
      await SignupVerificationService.instance.sendSignupVerification(
        email: trimmed,
      );
    } on AuthException {
      rethrow;
    } on gt.AuthException catch (e) {
      throw AuthException(_resendAuthMessage(e));
    } catch (e) {
      throw AuthException('Could not resend verification email. Please try again.');
    }
  }

  /// Checks that a patient/elderly account published this family link code.
  Future<bool> isFamilyLinkCodeValid(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;
    try {
      final result = await _client.rpc(
        'validate_family_link_code',
        params: {'link_code': trimmed},
      );
      if (result is bool) return result;
      return result == true;
    } catch (e) {
      debugPrint('isFamilyLinkCodeValid (rpc): $e');
      try {
        final row = await _client
            .from('users')
            .select('id')
            .eq('family_verification_code', trimmed)
            .inFilter('role', ['elderly', 'patient', 'user'])
            .limit(1)
            .maybeSingle();
        return row != null;
      } catch (e2) {
        debugPrint('isFamilyLinkCodeValid (fallback): $e2');
        return false;
      }
    }
  }

  static String _generateFamilyLinkCode() {
    final n = Random.secure().nextInt(0x10000);
    return 'CB-${DateTime.now().year}-${n.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }

  /// User-facing message for [resendSignupVerificationEmail] errors.
  String _resendAuthMessage(gt.AuthException e) {
    final m = e.message.toLowerCase();
    final code = e.code?.toLowerCase();

    if (code == 'over_email_send_rate_limit' ||
        m.contains('rate limit') ||
        m.contains('too many') ||
        m.contains('wait')) {
      return 'Too many requests. Supabase rate-limits email sends — please '
          'wait a minute and try again. (Tip: also check your spam folder.)';
    }
    if (m.contains('already') && m.contains('confirmed')) {
      return 'This email is already confirmed. Try signing in instead.';
    }
    if (code == 'user_not_found' || m.contains('user not found')) {
      return 'No account found for this email. Please sign up first.';
    }
    return e.message;
  }

  /// Clears Supabase session and persisted local session (via SDK).
  Future<void> signOut() => _client.auth.signOut();
}

