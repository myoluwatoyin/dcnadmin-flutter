// Role, account status, and derived persona enums shared across the app.
// Values mirror the backend's uppercase enum convention (see product brief).

enum Role {
  pastor,
  superAdmin,
  hod,
  subHod,
  worker;

  String get wire => switch (this) {
        Role.pastor => 'PASTOR',
        Role.superAdmin => 'SUPER_ADMIN',
        Role.hod => 'HOD',
        Role.subHod => 'SUBHOD',
        Role.worker => 'WORKER',
      };

  static Role? fromWire(String? v) => switch (v?.toUpperCase()) {
        'PASTOR' => Role.pastor,
        'SUPER_ADMIN' => Role.superAdmin,
        'HOD' => Role.hod,
        'SUBHOD' => Role.subHod,
        'WORKER' => Role.worker,
        _ => null,
      };
}

enum AccountStatus {
  pending,
  approved,
  suspended,
  rejected;

  String get wire => name.toUpperCase();

  static AccountStatus fromWire(String? v) => switch (v?.toUpperCase()) {
        'APPROVED' => AccountStatus.approved,
        'SUSPENDED' => AccountStatus.suspended,
        'REJECTED' => AccountStatus.rejected,
        _ => AccountStatus.pending,
      };
}

/// The mobile area a signed-in user is routed to. Derived from role + the
/// department code, per the brief's Session & Routing rules.
enum Persona {
  worker,
  followupWorker,
  hod,
  followupHod,
  pastor;

  String get wire => switch (this) {
        Persona.worker => 'worker',
        Persona.followupWorker => 'followup_worker',
        Persona.hod => 'hod',
        Persona.followupHod => 'followup_hod',
        Persona.pastor => 'pastor',
      };

  static Persona? fromWire(String? v) => switch (v) {
        'worker' => Persona.worker,
        'followup_worker' => Persona.followupWorker,
        'hod' => Persona.hod,
        'followup_hod' => Persona.followupHod,
        'pastor' => Persona.pastor,
        _ => null,
      };
}

/// The Follow-Up department's stable backend code.
const kFollowUpDeptCode = 'FOLLOWUP';

/// Pure persona derivation — the single source of truth for routing.
///
/// Rules (from the product brief):
///   SUPER_ADMIN | PASTOR                -> pastor
///   HOD + FOLLOWUP dept                 -> followup_hod
///   HOD | SUBHOD                        -> hod
///   FOLLOWUP dept (any remaining)       -> followup_worker
///   otherwise                          -> worker
Persona derivePersona({required Role? role, String? departmentCode}) {
  final isFollowUp = (departmentCode ?? '').toUpperCase() == kFollowUpDeptCode;
  switch (role) {
    case Role.pastor:
    case Role.superAdmin:
      return Persona.pastor;
    case Role.hod:
      return isFollowUp ? Persona.followupHod : Persona.hod;
    case Role.subHod:
      return Persona.hod;
    case Role.worker:
    case null:
      return isFollowUp ? Persona.followupWorker : Persona.worker;
  }
}
