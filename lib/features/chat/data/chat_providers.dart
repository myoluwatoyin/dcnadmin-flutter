import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../worker/data/worker_providers.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

/// Denormalized info for the signed-in user, used when creating conversations
/// and sending messages.
final myParticipantInfoProvider = Provider<ParticipantInfo?>((ref) {
  final u = ref.watch(authStateProvider).valueOrNull;
  if (u == null) return null;
  return ParticipantInfo(
    name: u.fullName.isNotEmpty ? u.fullName : 'Worker',
    photoUrl: u.photoUrl,
    role: u.role?.wire,
  );
});

/// The signed-in user's conversations, newest activity first.
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchConversations(uid);
});

/// Total unread conversations for the badge on the messages icon.
final chatUnreadCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  final convs = ref.watch(conversationsProvider).valueOrNull ?? const [];
  if (uid == null) return 0;
  return convs.where((c) => c.unreadFor(uid)).length;
});

/// Messages within a conversation.
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, convId) {
  return ref.watch(chatRepositoryProvider).watchMessages(convId);
});

/// A single conversation's live metadata (title, type, participants) — used by
/// the thread header and to label group messages.
final conversationProvider =
    StreamProvider.family<Conversation?, String>((ref, convId) {
  return ref.watch(chatRepositoryProvider).watchConversation(convId);
});

/// A worker who can be messaged (sourced from the public worker directory).
class ChatContact {
  const ChatContact({required this.uid, required this.name, this.photoUrl, this.role, this.department});
  final String uid;
  final String name;
  final String? photoUrl;
  final String? role;
  final String? department;
}

/// The approved-worker directory, minus the signed-in user — the pool for
/// starting a new chat.
final chatContactsProvider = StreamProvider<List<ChatContact>>((ref) {
  final me = ref.watch(currentUidProvider);
  return FirebaseFirestore.instance
      .collection('worker_directory')
      .where('status', isEqualTo: 'APPROVED')
      .snapshots()
      .map((s) => s.docs
          .where((d) => d.id != me)
          .map((d) {
            final m = d.data();
            return ChatContact(
              uid: d.id,
              name: (m['name'] ?? '') as String,
              photoUrl: m['photo_url'] as String?,
              role: m['role'] as String?,
              department: m['department_name'] as String?,
            );
          })
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
});
