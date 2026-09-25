import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetingType { regular, service, emergency, adHoc }

enum MeetingStatus { scheduled, rescheduled, cancelled }

/// A meeting/service on a worker's schedule.
class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.date = '',
    this.start = '',
    this.end = '',
    this.location = '',
    this.agenda,
    this.reason,
    this.startAt,
    this.audienceCount = 0,
  });

  final String id;
  final String title;
  final MeetingType type;
  final MeetingStatus status;
  final String date;
  final String start;
  final String end;
  final String location;
  final String? agenda;
  final String? reason;
  final DateTime? startAt;
  final int audienceCount;

  static MeetingType _type(String? v) => switch (v?.toUpperCase()) {
        'SERVICE' => MeetingType.service,
        'EMERGENCY' => MeetingType.emergency,
        'AD_HOC' => MeetingType.adHoc,
        _ => MeetingType.regular,
      };

  static MeetingStatus _status(String? v) => switch (v?.toUpperCase()) {
        'RESCHEDULED' => MeetingStatus.rescheduled,
        'CANCELLED' => MeetingStatus.cancelled,
        _ => MeetingStatus.scheduled,
      };

  factory Meeting.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['start_at'];
    return Meeting(
      id: id,
      title: (m['title'] ?? '') as String,
      type: _type(m['type'] as String?),
      status: _status(m['status'] as String?),
      date: (m['date'] ?? '') as String,
      start: (m['start'] ?? '') as String,
      end: (m['end'] ?? '') as String,
      location: (m['location'] ?? '') as String,
      agenda: m['agenda'] as String?,
      reason: m['reason'] as String?,
      startAt: ts is Timestamp ? ts.toDate() : null,
      audienceCount: ((m['audience_uids'] as List?) ?? const []).length,
    );
  }
}
