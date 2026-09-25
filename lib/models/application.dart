/// A pending signup application awaiting HOD/Pastor approval.
class Application {
  const Application({
    required this.id,
    required this.name,
    this.appliedLabel = '',
    this.school = '',
    this.level = '',
    this.subUnitPref = '',
    this.responsibilities = const [],
    this.phone = '',
    this.department = '',
    this.status = 'PENDING',
  });

  final String id;
  final String name;
  final String appliedLabel;
  final String school;
  final String level;
  final String subUnitPref;
  final List<String> responsibilities;
  final String phone;
  final String department;
  final String status;

  factory Application.fromMap(String id, Map<String, dynamic> m) {
    final first = (m['first_name'] ?? '') as String;
    final last = (m['last_name'] ?? '') as String;
    final composed = [first, last].where((s) => s.isNotEmpty).join(' ');
    return Application(
      id: id,
      name: composed.isNotEmpty ? composed : (m['name'] ?? '') as String,
      appliedLabel: (m['applied_label'] ?? '') as String,
      school: (m['school'] ?? '') as String,
      level: (m['level'] ?? '') as String,
      subUnitPref: (m['sub_unit_pref'] ?? '') as String,
      responsibilities:
          ((m['responsibilities'] as List?) ?? const []).cast<String>(),
      phone: (m['phone_number'] ?? m['phone'] ?? '') as String,
      department: (m['department'] ?? '') as String,
      status: (m['status'] ?? 'PENDING') as String,
    );
  }
}
