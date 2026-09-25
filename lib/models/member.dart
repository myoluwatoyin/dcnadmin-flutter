import 'package:cloud_firestore/cloud_firestore.dart';

/// A follow-up note logged against a member.
class FollowUpNote {
  const FollowUpNote({required this.from, required this.at, required this.body});
  final String from;
  final String at;
  final String body;

  factory FollowUpNote.fromMap(Map<String, dynamic> m) => FollowUpNote(
        from: (m['from'] ?? '') as String,
        at: (m['at'] ?? '') as String,
        body: (m['body'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {'from': from, 'at': at, 'body': body};
}

/// A church member the follow-up team manages.
class Member {
  const Member({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.dob = '',
    this.category = 'Member',
    this.status = 'Active',
    this.weeksAbsent = 0,
    this.lastAttended = '',
    this.school = '',
    this.faculty = '',
    this.level = '',
    this.address = '',
    this.firstSeen = '',
    this.assignedWorkerUid = '',
    this.unreachable = false,
    this.pipelineStatus = '',
    this.weekNumber = 0,
    this.inQueue = false,
    this.queuePriority = 'med',
    this.queueReason = '',
    this.queueStatus = 'PENDING',
    this.lastOutcome = '',
    this.nextBirthdayLabel = '',
    this.photoUrl,
    this.followUpNotes = const [],
    this.attendance = const [],
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String category; // First-Timer | Member | Fresher | Old Member
  final String status; // Active | At Risk | Unreachable | First-Timer
  final int weeksAbsent;
  final String lastAttended;
  final String school;
  final String faculty;
  final String level;
  final String address;
  final String firstSeen;
  final String assignedWorkerUid;
  final bool unreachable;
  final String pipelineStatus; // first-timer pipeline stage
  final int weekNumber;
  final bool inQueue;
  final String queuePriority; // low | med | high | urgent
  final String queueReason;
  final String queueStatus; // PENDING | DONE
  final String lastOutcome;
  final String nextBirthdayLabel; // "Today", "In 2 days", "" if none soon
  final String? photoUrl;
  final List<FollowUpNote> followUpNotes;
  final List<bool> attendance; // last 12 Sundays, newest last

  bool get isFirstTimer => category == 'First-Timer';
  bool get isAtRisk => status == 'At Risk';
  bool get queueDone => queueStatus == 'DONE';

  int get attendanceRate => attendance.isEmpty
      ? 0
      : ((attendance.where((v) => v).length / attendance.length) * 100).round();

  factory Member.fromMap(String id, Map<String, dynamic> m) {
    final notes = ((m['follow_up_notes'] as List?) ?? const [])
        .whereType<Map>()
        .map((n) => FollowUpNote.fromMap(Map<String, dynamic>.from(n)))
        .toList()
        .reversed // appended at the end; show newest first
        .toList();
    return Member(
      id: id,
      name: (m['name'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      dob: (m['dob'] ?? '') as String,
      category: (m['category'] ?? 'Member') as String,
      status: (m['status'] ?? 'Active') as String,
      weeksAbsent: (m['weeks_absent'] ?? 0) as int,
      lastAttended: (m['last_attended'] ?? '') as String,
      school: (m['school'] ?? '') as String,
      faculty: (m['faculty'] ?? '') as String,
      level: (m['level'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      firstSeen: (m['first_seen'] ?? '') as String,
      assignedWorkerUid: (m['assigned_worker_uid'] ?? '') as String,
      unreachable: (m['unreachable'] ?? false) as bool,
      pipelineStatus: (m['pipeline_status'] ?? '') as String,
      weekNumber: (m['week_number'] ?? 0) as int,
      inQueue: (m['in_queue'] ?? false) as bool,
      queuePriority: (m['queue_priority'] ?? 'med') as String,
      queueReason: (m['queue_reason'] ?? '') as String,
      queueStatus: (m['queue_status'] ?? 'PENDING') as String,
      lastOutcome: (m['last_outcome'] ?? '') as String,
      nextBirthdayLabel: (m['next_birthday_label'] ?? '') as String,
      photoUrl: m['photo_url'] as String?,
      followUpNotes: notes,
      attendance: ((m['attendance'] as List?) ?? const [])
          .map((v) => v == true || v == 1)
          .toList(),
    );
  }
}

/// A follow-up assignment note appended atomically to a member.
Map<String, dynamic> followUpNoteData(String from, String body) => {
      'from': from,
      'at': 'Just now',
      'body': body,
      'ts': Timestamp.now(),
    };
