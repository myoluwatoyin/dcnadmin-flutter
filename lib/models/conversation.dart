import 'package:cloud_firestore/cloud_firestore.dart';

/// Denormalized participant info stored on the conversation so the list can
/// render names/avatars without extra reads.
class ParticipantInfo {
  const ParticipantInfo({required this.name, this.photoUrl, this.role});
  final String name;
  final String? photoUrl;
  final String? role;

  factory ParticipantInfo.fromMap(Map<String, dynamic> m) => ParticipantInfo(
        name: (m['name'] ?? '') as String,
        photoUrl: m['photo_url'] as String?,
        role: m['role'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'photo_url': photoUrl,
        'role': role,
      };
}

/// A chat conversation — a 1:1 direct thread or a group. Participants and the
/// last-message summary are denormalized for a cheap conversation list.
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.participantUids,
    required this.participants,
    this.title = '',
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastSenderUid = '',
    this.readAt = const {},
  });

  final String id;
  final String type; // 'direct' | 'group'
  final List<String> participantUids;
  final Map<String, ParticipantInfo> participants;
  final String title;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderUid;
  final Map<String, DateTime> readAt;

  bool get isGroup => type == 'group';

  /// The other party's uid in a direct chat (falls back to first participant).
  String otherUid(String me) =>
      participantUids.firstWhere((u) => u != me, orElse: () => me);

  /// Title to show relative to the signed-in user.
  String displayTitle(String me) {
    if (isGroup) return title.isNotEmpty ? title : 'Group';
    return participants[otherUid(me)]?.name ?? title;
  }

  String? displayPhoto(String me) {
    if (isGroup) return null;
    return participants[otherUid(me)]?.photoUrl;
  }

  /// True if there's an unread inbound message for [me].
  bool unreadFor(String me) {
    if (lastMessageAt == null || lastSenderUid == me) return false;
    final read = readAt[me];
    return read == null || read.isBefore(lastMessageAt!);
  }

  factory Conversation.fromMap(String id, Map<String, dynamic> m) {
    final parts = <String, ParticipantInfo>{};
    (m['participants'] as Map?)?.forEach((k, v) {
      if (v is Map) parts[k as String] = ParticipantInfo.fromMap(Map<String, dynamic>.from(v));
    });
    final reads = <String, DateTime>{};
    (m['read_at'] as Map?)?.forEach((k, v) {
      if (v is Timestamp) reads[k as String] = v.toDate();
    });
    return Conversation(
      id: id,
      type: (m['type'] ?? 'direct') as String,
      participantUids: ((m['participant_uids'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      participants: parts,
      title: (m['title'] ?? '') as String,
      lastMessage: (m['last_message'] ?? '') as String,
      lastMessageAt: (m['last_message_at'] as Timestamp?)?.toDate(),
      lastSenderUid: (m['last_sender_uid'] ?? '') as String,
      readAt: reads,
    );
  }
}
