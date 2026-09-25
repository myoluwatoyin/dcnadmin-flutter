/// A sign-up invite code the Pastor generates and manages.
class InviteCode {
  const InviteCode({
    required this.id,
    required this.code,
    this.role = 'WORKER',
    this.departmentName = '',
    this.usesTotal = 0,
    this.uses = 0,
    this.expires = '',
    this.active = true,
  });

  final String id;
  final String code;
  final String role;
  final String departmentName;
  final int usesTotal;
  final int uses;
  final String expires;
  final bool active;

  int get usesLeft => (usesTotal - uses).clamp(0, usesTotal);

  /// ACTIVE | EXHAUSTED | REVOKED
  String get status {
    if (!active) return 'REVOKED';
    if (usesTotal > 0 && usesLeft <= 0) return 'EXHAUSTED';
    return 'ACTIVE';
  }

  factory InviteCode.fromMap(String id, Map<String, dynamic> m) => InviteCode(
        id: id,
        code: (m['code'] ?? '') as String,
        role: (m['role'] ?? 'WORKER') as String,
        departmentName: (m['department_name'] ?? m['department_code'] ?? '') as String,
        usesTotal: (m['max_uses'] ?? 0) as int,
        uses: (m['uses'] ?? 0) as int,
        expires: (m['expires'] ?? '') as String,
        active: (m['active'] ?? true) as bool,
      );
}
