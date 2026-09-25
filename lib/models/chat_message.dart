import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message within a conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    this.text = '',
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  bool get hasImage => (imageUrl ?? '').isNotEmpty;
  bool isMine(String me) => senderUid == me;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderUid: (m['sender_uid'] ?? '') as String,
        senderName: (m['sender_name'] ?? '') as String,
        text: (m['text'] ?? '') as String,
        imageUrl: m['image_url'] as String?,
        createdAt: (m['created_at'] as Timestamp?)?.toDate(),
      );
}
