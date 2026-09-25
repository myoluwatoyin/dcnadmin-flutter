import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app notification addressed to a user.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    this.type = '',
    this.urgent = false,
    this.at = '',
    this.createdAt,
    this.route,
    this.partnerName,
    this.partnerSub,
    this.partnerNote,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String type;
  final bool urgent;
  final String at;
  final DateTime? createdAt;

  /// Deep-link target (e.g. `/task/xxx`, `/meeting/yyy`), if any.
  final String? route;

  // Partner-request payload (type == PARTNER_REQUEST).
  final String? partnerName;
  final String? partnerSub;
  final String? partnerNote;

  bool get isPartnerRequest => type == 'PARTNER_REQUEST';

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['created_at'];
    return AppNotification(
      id: id,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      read: (m['read'] ?? false) as bool,
      type: (m['type'] ?? '') as String,
      urgent: (m['urgent'] ?? false) as bool,
      at: (m['at'] ?? '') as String,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      route: m['route'] as String?,
      partnerName: m['partner_name'] as String?,
      partnerSub: m['partner_sub'] as String?,
      partnerNote: m['partner_note'] as String?,
    );
  }
}
