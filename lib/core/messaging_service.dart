import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';

/// Background handler — MUST be a top-level function annotated for the VM.
/// FCM shows the system notification automatically; nothing to do here beyond
/// existing so background/terminated delivery works.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the notification payload is displayed by the OS. Tap handling runs
  // in the foreground isolate via onMessageOpenedApp / getInitialMessage.
}

/// Registers the device for push, stores its FCM token under the signed-in
/// user, and routes notification taps into the chat thread.
class MessagingService {
  MessagingService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _fm = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _fm;
  final FirebaseFirestore _db;

  String? _uid;
  String? _token;
  bool _listenersReady = false;

  /// Call after sign-in. Requests permission, saves the token, wires listeners.
  Future<void> initForUser(String uid) async {
    if (_uid == uid && _token != null) return;
    _uid = uid;

    await _fm.requestPermission(alert: true, badge: true, sound: true);

    // iOS needs the APNS token before an FCM token is available.
    try {
      final token = await _fm.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (_) {/* token not ready yet; refresh listener will catch it */}

    _fm.onTokenRefresh.listen((t) {
      if (_uid != null) _saveToken(_uid!, t);
    });

    if (!_listenersReady) {
      _listenersReady = true;
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await _fm.getInitialMessage();
      if (initial != null) _handleTap(initial);
    }
  }

  /// Call on sign-out so a shared device stops receiving the old user's pushes.
  Future<void> clearForUser() async {
    final uid = _uid;
    final token = _token;
    _uid = null;
    _token = null;
    if (uid != null && token != null) {
      await _db.collection('users').doc(uid).collection('fcm_tokens').doc(token).delete().catchError((_) {});
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    _token = token;
    await _db.collection('users').doc(uid).collection('fcm_tokens').doc(token).set({
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  void _handleTap(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'chat' && (data['conversation_id'] ?? '').toString().isNotEmpty) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).push('/chat/thread/${data['conversation_id']}',
            extra: {'title': data['title'] as String?});
      }
    }
  }
}
