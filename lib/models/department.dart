/// A ministry department and its sub-units, fetched from the backend for the
/// signup Ministry step. Shape mirrors the old `/departments` endpoint.
class Department {
  const Department({
    required this.id,
    required this.name,
    required this.code,
    this.requiresSubUnit = false,
    this.subUnits = const [],
  });

  final String id;
  final String name;
  final String code;
  final bool requiresSubUnit;
  final List<SubUnit> subUnits;

  factory Department.fromMap(String id, Map<String, dynamic> m) {
    final rawUnits = (m['sub_units'] as List?) ?? const [];
    return Department(
      id: id,
      name: (m['name'] ?? '') as String,
      code: (m['code'] ?? '') as String,
      requiresSubUnit: (m['requires_sub_unit'] ?? false) as bool,
      subUnits: rawUnits
          .whereType<Map>()
          .map((u) => SubUnit.fromMap(Map<String, dynamic>.from(u)))
          .toList(),
    );
  }
}

class SubUnit {
  const SubUnit({required this.id, required this.name});

  final String id;
  final String name;

  factory SubUnit.fromMap(Map<String, dynamic> m) =>
      SubUnit(id: (m['id'] ?? '') as String, name: (m['name'] ?? '') as String);
}

/// A minimal approved-worker record returned by the inviter search
/// (old `/workers/search`).
class WorkerRef {
  const WorkerRef({
    required this.id,
    required this.name,
    this.departmentName,
    this.subUnitName,
    this.role,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? departmentName;
  final String? subUnitName;
  final String? role;
  final String? photoUrl;

  factory WorkerRef.fromMap(String id, Map<String, dynamic> m) {
    final first = m['first_name'] as String?;
    final last = m['last_name'] as String?;
    final composed = [first, last].where((s) => (s ?? '').isNotEmpty).join(' ');
    return WorkerRef(
      id: id,
      name: composed.isNotEmpty ? composed : (m['name'] ?? '') as String,
      departmentName: m['department_name'] as String?,
      subUnitName: m['sub_unit_name'] as String?,
      role: m['role'] as String?,
      photoUrl: m['photo_url'] as String?,
    );
  }
}
