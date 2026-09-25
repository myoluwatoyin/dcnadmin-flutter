import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';

/// Firestore-backed chat: conversations + a messages subcollection. Direct
/// (1:1) threads use a deterministic id so the same pair never creates two.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _convs => _db.collection('conversations');

  static String directId(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  Stream<List<Conversation>> watchConversations(String uid) {
    return _convs
        .where('participant_uids', arrayContains: uid)
        .orderBy('last_message_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Conversation.fromMap(d.id, d.data())).toList());
  }

  Stream<Conversation?> watchConversation(String convId) {
    return _convs.doc(convId).snapshots().map(
        (d) => d.exists ? Conversation.fromMap(d.id, d.data()!) : null);
  }

  Stream<List<ChatMessage>> watchMessages(String convId) {
    return _convs
        .doc(convId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .limit(300)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  Future<Conversation?> getConversation(String convId) async {
    final snap = await _convs.doc(convId).get();
    if (!snap.exists) return null;
    return Conversation.fromMap(snap.id, snap.data()!);
  }

  /// Opens (creating if needed) the direct thread between [me] and [other],
  /// returning its id.
  Future<String> openDirect({
    required String me,
    required ParticipantInfo meInfo,
    required String other,
    required ParticipantInfo otherInfo,
  }) async {
    final id = directId(me, other);
    final ref = _convs.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'type': 'direct',
        'participant_uids': [me, other],
        'participants': {me: meInfo.toMap(), other: otherInfo.toMap()},
        'title': '',
        'last_message': '',
        'last_sender_uid': '',
        'read_at': {me: FieldValue.serverTimestamp()},
        'created_by': me,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  /// Creates a group conversation (random id). [participants] must include the
  /// creator. Returns the new conversation id.
  Future<String> createGroup({
    required String title,
    required String creatorUid,
    required Map<String, ParticipantInfo> participants,
  }) async {
    final ref = _convs.doc();
    await ref.set({
      'type': 'group',
      'participant_uids': participants.keys.toList(),
      'participants': participants.map((k, v) => MapEntry(k, v.toMap())),
      'title': title,
      'last_message': '',
      'last_sender_uid': '',
      'read_at': {creatorUid: FieldValue.serverTimestamp()},
      'created_by': creatorUid,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Appends a message and updates the conversation summary in one batch.
  Future<void> sendMessage(
    String convId, {
    required String senderUid,
    required String senderName,
    String text = '',
    String? imageUrl,
  }) async {
    final batch = _db.batch();
    final msgRef = _convs.doc(convId).collection('messages').doc();
    batch.set(msgRef, {
      'sender_uid': senderUid,
      'sender_name': senderName,
      'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(
      _convs.doc(convId),
      {
        'last_message': (imageUrl != null && text.isEmpty) ? '📷 Photo' : text,
        'last_message_at': FieldValue.serverTimestamp(),
        'last_sender_uid': senderUid,
        'read_at': {senderUid: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Marks the conversation read up to now for [uid].
  Future<void> markRead(String convId, String uid) {
    return _convs.doc(convId).set(
      {
        'read_at': {uid: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
  }
}
