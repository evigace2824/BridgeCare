/// Roles supported by BridgeCare and stored in `public.users.role` (and auth metadata).
enum UserRole { elderly, family, volunteer, admin }

/// **Domain model** for one BridgeCare user: maps a Supabase row from `public.users`
/// plus optional nested `volunteer_profiles` data.
///
/// **Why this class exists**
/// - Supabase returns **JSON maps**; turning them into a typed [UserModel] catches mistakes
///   at compile time and keeps UI code readable (`profile.homeRoute` vs string keys).
/// - **Separation of concerns:** [AuthService] loads maps from the API; screens consume
///   [UserModel] without knowing SQL column names everywhere.
///
/// **What it consists of**
/// - **Identity / profile:** [id] (matches `auth.users.id`), [name], [email], [role],
///   [phoneNumber], [address], [avatarUrl], [isProfileComplete], [familyVerificationCode], [createdAt].
/// - **Volunteer extension:** when the query joins `volunteer_profiles`, [volunteerSkills],
///   [availability], [transport] are filled.
/// - **Navigation helpers:** [homeRoute] picks the Material route for [role]; [postAuthRoute]
///   sends incomplete OAuth profiles to `/role_onboarding` first.
/// - **Serialization helpers:** [fromMap], [toUserTableMap], [toVolunteerProfileMap] for
///   read/update round-trips with PostgREST.
class UserModel {
  // --- Fields from 'public.users' table ---
  final String id;
  final String? name;
  final String? email;
  final UserRole role;
  final String? phoneNumber;
  final String? address;
  final String? avatarUrl;
  final bool isProfileComplete;
  final String? familyVerificationCode;
  final DateTime createdAt;

  // --- Fields from 'public.volunteer_profiles' table ---
  final String? volunteerSkills; // SQL type: TEXT
  final String? availability; // SQL type: VARCHAR(100)
  final String? transport; // SQL type: VARCHAR(50)

  const UserModel({
    required this.id,
    this.name,
    this.email,
    required this.role,
    this.phoneNumber,
    this.address,
    this.avatarUrl,
    this.isProfileComplete = false,
    this.familyVerificationCode,
    required this.createdAt,
    // Volunteer fields
    this.volunteerSkills,
    this.availability,
    this.transport,
  });

  /// UI-friendly alias: same as [name] from the database.
  String? get fullName => name;

  /// **Route name** for the signed-in user's dashboard (must exist in [MaterialApp.routes]).
  ///
  /// Maps [UserRole] → `/home_user`, `/home_family`, `/home_volunteer`, `/home_admin`.
  ///
  /// **Elderly / end users:** [UserRole.elderly] → `/home_user` (elderly home dashboard).
  /// Unknown or legacy role strings in the database default to [UserRole.elderly]
  /// (see [_parseRole]) so the user always has a safe home route.
  String get homeRoute {
    switch (role) {
      case UserRole.elderly:
        return '/home_user';
      case UserRole.family:
        return '/home_family';
      case UserRole.volunteer:
        return '/home_volunteer';
      case UserRole.admin:
        return '/home_admin';
    }
  }

  /// **Where to go immediately after a successful sign-in.**
  ///
  /// If [isProfileComplete] is `false` (typical for first-time Google users with a
  /// minimal DB row), returns `/role_onboarding` so they choose role + name. Otherwise
  /// returns [homeRoute].
  String get postAuthRoute =>
      isProfileComplete ? homeRoute : '/role_onboarding';

  /// Builds a [UserModel] from one Supabase JSON object (e.g. `select('*, volunteer_profiles(*)')`).
  ///
  /// - Parses nested `volunteer_profiles` whether PostgREST returns a map or a one-element list.
  /// - Parses `created_at` from string or [DateTime].
  /// - Maps DB `role` text to [UserRole] via [_parseRole].
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Check if volunteer_profiles data was joined in the query
    final rawVol = map['volunteer_profiles'];
    final Map<String, dynamic>? volProfile = _firstNestedMap(rawVol);

    final createdRaw = map['created_at'];
    final createdAt = createdRaw is DateTime
        ? createdRaw
        : DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now();

    return UserModel(
      id: map['id'].toString(),
      name: map['name'] as String?,
      email: map['email'] as String?,
      role: _parseRole(map['role']?.toString()),
      phoneNumber: map['phone_number'] as String?,
      address: map['address'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isProfileComplete: map['is_profile_complete'] as bool? ?? false,
      familyVerificationCode: map['family_verification_code'] as String?,
      createdAt: createdAt,
      volunteerSkills: volProfile?['skills'] as String?,
      availability: volProfile?['availability'] as String?,
      transport: volProfile?['transport'] as String?,
    );
  }

  /// Normalizes PostgREST nested shape: single object, map, or list of one object → one map.
  static Map<String, dynamic>? _firstNestedMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  /// Converts profile fields into a patch map for `update` on `public.users`
  /// (columns that users may edit from settings / complete-profile flows).
  Map<String, dynamic> toUserTableMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'address': address,
      'is_profile_complete': isProfileComplete,
      'family_verification_code': familyVerificationCode,
      // Note: id, email, role, and created_at are usually handled by Auth/Trigger
    };
  }

  /// Converts volunteer fields into a row for `volunteer_profiles` upsert (`user_id` = [id]).
  Map<String, dynamic> toVolunteerProfileMap() {
    return {
      'user_id': id,
      'skills': volunteerSkills,
      'availability': availability,
      'transport': transport,
    };
  }

  /// Maps stored role strings (and legacy aliases like `patient`, `caregiver`) to [UserRole].
  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'volunteer':
        return UserRole.volunteer;
      case 'family':
      case 'caregiver':
        return UserRole.family;
      case 'admin':
        return UserRole.admin;
      case 'elderly':
      case 'patient':
      case 'user':
      default:
        return UserRole.elderly;
    }
  }
}
