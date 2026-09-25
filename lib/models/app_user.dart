import 'enums.dart';

/// The signed-in user's session profile. Modeled on the old backend's login
/// response shape (see product brief), sourced from a Firestore user document
/// and/or Firebase Auth custom claims in the rebuild.
class AppUser {
  const AppUser({
    required this.id,
    required this.memberId,
    required this.role,
    required this.status,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    this.subUnitId,
    this.subUnitName,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.phone,
    this.email,
    this.accessKey,
    this.school,
    this.level,
    this.dob,
    this.joinedLabel,
  });

  final String id;
  final String memberId;
  final Role? role;
  final AccountStatus status;
  final String? departmentId;
  final String? departmentName;
  final String? departmentCode;
  final String? subUnitId;
  final String? subUnitName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? phone;
  final String? email;
  final String? accessKey;
  final String? school;
  final String? level;
  final String? dob;
  final String? joinedLabel;

  /// The mobile area this user routes into.
  Persona get persona => derivePersona(role: role, departmentCode: departmentCode);

  String get fullName =>
      [firstName, lastName].where((s) => (s ?? '').isNotEmpty).join(' ').trim();

  bool get isApproved => status == AccountStatus.approved;
  bool get isSuspended => status == AccountStatus.suspended;

  factory AppUser.fromMap(String id, Map<String, dynamic> m) {
    return AppUser(
      id: id,
      memberId: (m['member_id'] ?? '') as String,
      role: Role.fromWire(m['role'] as String?),
      status: AccountStatus.fromWire(m['status'] as String?),
      departmentId: m['department_id'] as String?,
      departmentName: m['department_name'] as String?,
      departmentCode: m['department_code'] as String?,
      subUnitId: m['sub_unit_id'] as String?,
      subUnitName: m['sub_unit_name'] as String?,
      firstName: (m['person'] as Map?)?['first_name'] as String? ??
          m['first_name'] as String?,
      lastName: (m['person'] as Map?)?['last_name'] as String? ??
          m['last_name'] as String?,
      photoUrl: (m['person'] as Map?)?['photo_url'] as String? ??
          m['photo_url'] as String?,
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      accessKey: m['access_key'] as String?,
      school: m['school'] as String?,
      level: m['level'] as String?,
      dob: m['dob'] as String?,
      joinedLabel: m['joined_label'] as String?,
    );
  }
}
