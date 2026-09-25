/// SMS template (automated or manual).
class SmsTemplate {
  const SmsTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.body,
  });

  final String id;
  final String name;
  final String category; // AUTO | MANUAL
  final String body;

  bool get isAuto => category == 'AUTO';

  factory SmsTemplate.fromMap(String id, Map<String, dynamic> m) => SmsTemplate(
        id: id,
        name: (m['name'] ?? '') as String,
        category: (m['category'] ?? 'AUTO') as String,
        body: (m['body'] ?? '') as String,
      );
}

/// An absence SMS rule: after `threshold` misses of `service`, send `template`.
class SmsRule {
  const SmsRule({
    required this.id,
    required this.service,
    required this.threshold,
    required this.templateName,
    required this.body,
    required this.active,
  });

  final String id;
  final String service; // sunday | tuesday
  final int threshold;
  final String templateName;
  final String body;
  final bool active;

  factory SmsRule.fromMap(String id, Map<String, dynamic> m) => SmsRule(
        id: id,
        service: (m['service'] ?? 'sunday') as String,
        threshold: (m['threshold'] ?? 0) as int,
        templateName: (m['template_name'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        active: (m['active'] ?? true) as bool,
      );
}

/// A sent SMS log entry.
class SmsLogEntry {
  const SmsLogEntry({
    required this.id,
    required this.to,
    this.toPhone = '',
    this.type = '',
    this.template = '',
    this.status = 'DELIVERED',
    this.sentAt = '',
    this.auto = false,
    this.error = '',
    this.sortKey = 0,
  });

  final String id;
  final String to;
  final String toPhone;
  final String type; // ABSENCE | BIRTHDAY | MEETING | BLAST
  final String template;
  final String status; // DELIVERED | FAILED
  final String sentAt;
  final bool auto;
  final String error;
  final int sortKey;

  bool get failed => status == 'FAILED';

  factory SmsLogEntry.fromMap(String id, Map<String, dynamic> m) => SmsLogEntry(
        id: id,
        to: (m['to'] ?? '') as String,
        toPhone: (m['to_phone'] ?? '') as String,
        type: (m['type'] ?? '') as String,
        template: (m['template'] ?? '') as String,
        status: (m['status'] ?? 'DELIVERED') as String,
        sentAt: (m['sent_at'] ?? '') as String,
        auto: (m['auto'] ?? false) as bool,
        error: (m['error'] ?? '') as String,
        sortKey: (m['sort_key'] ?? 0) as int,
      );
}
