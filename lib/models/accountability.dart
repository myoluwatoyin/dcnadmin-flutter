/// A worker's accountability partner and weekly check-in history.
class Accountability {
  const Accountability({
    required this.partnerName,
    this.partnerDept = '',
    this.youSubmitted = false,
    this.youSubmittedLabel = '',
    this.partnerSubmitted = false,
    this.partnerSubmittedLabel = '',
    this.history = const [],
  });

  final String partnerName;
  final String partnerDept;
  final bool youSubmitted;
  final String youSubmittedLabel;
  final bool partnerSubmitted;
  final String partnerSubmittedLabel;
  final List<CheckIn> history;

  factory Accountability.fromMap(Map<String, dynamic> m) {
    return Accountability(
      partnerName: (m['partner_name'] ?? '') as String,
      partnerDept: (m['partner_dept'] ?? '') as String,
      youSubmitted: (m['you_submitted'] ?? false) as bool,
      youSubmittedLabel: (m['you_submitted_label'] ?? '') as String,
      partnerSubmitted: (m['partner_submitted'] ?? false) as bool,
      partnerSubmittedLabel: (m['partner_submitted_label'] ?? '') as String,
      history: ((m['history'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => CheckIn.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

class CheckIn {
  const CheckIn({required this.week, required this.both});
  final String week;
  final bool both;

  factory CheckIn.fromMap(Map<String, dynamic> m) =>
      CheckIn(week: (m['week'] ?? '') as String, both: (m['both'] ?? false) as bool);
}
