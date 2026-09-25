/// A department worker as seen by their HOD (denormalized summary fields from
/// the user doc).
class TeamWorker {
  const TeamWorker({
    required this.uid,
    required this.name,
    this.subUnit = '',
    this.role = 'WORKER',
    this.phone = '',
    this.bibleReport = false,
    this.prayerReport = false,
    this.tasksOpen = 0,
    this.tasksOverdue = 0,
    this.attendanceRate = 0,
    this.scorecardLast = 0,
    this.weeksWithUs = 0,
    this.atRisk = false,
    this.fuAssigned = 0,
    this.fuContacted = 0,
    this.fuQueueDonePct = 0,
    this.fuUnreachableHandled = 0,
    this.memberId = '',
    this.email = '',
    this.departmentName = '',
    this.status = 'APPROVED',
    this.suspendReason = '',
  });

  final String uid;
  final String name;
  final String subUnit;
  final String role;
  final String phone;
  final bool bibleReport;
  final bool prayerReport;
  final int tasksOpen;
  final int tasksOverdue;
  final int attendanceRate;
  final int scorecardLast;
  final int weeksWithUs;
  final bool atRisk;
  // Follow-Up worker performance (present on FOLLOWUP-dept workers).
  final int fuAssigned;
  final int fuContacted;
  final int fuQueueDonePct;
  final int fuUnreachableHandled;
  final String memberId;
  final String email;
  final String departmentName;
  final String status;
  final String suspendReason;

  bool get isSubHod => role.toUpperCase() == 'SUBHOD';
  bool get isHod => role.toUpperCase() == 'HOD';
  bool get isSuspended => status.toUpperCase() == 'SUSPENDED';
  bool get bothReports => bibleReport && prayerReport;
  bool get someReports => bibleReport || prayerReport;

  factory TeamWorker.fromMap(String uid, Map<String, dynamic> m) {
    final person = (m['person'] as Map?) ?? const {};
    final first = (person['first_name'] ?? m['first_name'] ?? '') as String;
    final last = (person['last_name'] ?? m['last_name'] ?? '') as String;
    final composed = [first, last].where((s) => s.isNotEmpty).join(' ');
    final reports = (m['week_reports'] as Map?) ?? const {};
    return TeamWorker(
      uid: uid,
      name: composed.isNotEmpty ? composed : (m['name'] ?? '') as String,
      subUnit: (m['sub_unit_name'] ?? '') as String,
      role: (m['role'] ?? 'WORKER') as String,
      phone: (m['phone'] ?? '') as String,
      bibleReport: (reports['bible'] ?? false) as bool,
      prayerReport: (reports['prayer'] ?? false) as bool,
      tasksOpen: (m['tasks_open'] ?? 0) as int,
      tasksOverdue: (m['tasks_overdue'] ?? 0) as int,
      attendanceRate: (m['attendance_rate'] ?? 0) as int,
      scorecardLast: (m['scorecard_last'] ?? 0) as int,
      weeksWithUs: (m['weeks_with_us'] ?? 0) as int,
      atRisk: (m['at_risk'] ?? false) as bool,
      fuAssigned: (m['fu_assigned'] ?? 0) as int,
      fuContacted: (m['fu_contacted'] ?? 0) as int,
      fuQueueDonePct: (m['fu_queue_done_pct'] ?? 0) as int,
      fuUnreachableHandled: (m['fu_unreachable_handled'] ?? 0) as int,
      memberId: (m['member_id'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      departmentName: (m['department_name'] ?? '') as String,
      status: (m['status'] ?? 'APPROVED') as String,
      suspendReason: (m['suspend_reason'] ?? '') as String,
    );
  }
}
