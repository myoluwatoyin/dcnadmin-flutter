import 'package:dcnadmin/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('derivePersona', () {
    test('PASTOR and SUPER_ADMIN route to pastor', () {
      expect(derivePersona(role: Role.pastor), Persona.pastor);
      expect(derivePersona(role: Role.superAdmin), Persona.pastor);
      // Department code is irrelevant for pastor/admin.
      expect(
        derivePersona(role: Role.pastor, departmentCode: 'FOLLOWUP'),
        Persona.pastor,
      );
    });

    test('HOD in Follow-Up department routes to followup_hod', () {
      expect(
        derivePersona(role: Role.hod, departmentCode: 'FOLLOWUP'),
        Persona.followupHod,
      );
      // Case-insensitive on the code.
      expect(
        derivePersona(role: Role.hod, departmentCode: 'followup'),
        Persona.followupHod,
      );
    });

    test('HOD and SUBHOD in other departments route to hod', () {
      expect(derivePersona(role: Role.hod, departmentCode: 'DRAMA'), Persona.hod);
      expect(derivePersona(role: Role.subHod, departmentCode: 'MEDIA'), Persona.hod);
      // SUBHOD in Follow-Up still routes to hod (not followup_hod).
      expect(
        derivePersona(role: Role.subHod, departmentCode: 'FOLLOWUP'),
        Persona.hod,
      );
    });

    test('Follow-Up worker routes to followup_worker', () {
      expect(
        derivePersona(role: Role.worker, departmentCode: 'FOLLOWUP'),
        Persona.followupWorker,
      );
    });

    test('Other workers and unknown roles route to worker', () {
      expect(derivePersona(role: Role.worker, departmentCode: 'DRAMA'), Persona.worker);
      expect(derivePersona(role: null, departmentCode: null), Persona.worker);
    });
  });

  group('enum wire mapping', () {
    test('Role round-trips through wire values', () {
      for (final r in Role.values) {
        expect(Role.fromWire(r.wire), r);
      }
    });

    test('AccountStatus falls back to pending on unknown', () {
      expect(AccountStatus.fromWire('APPROVED'), AccountStatus.approved);
      expect(AccountStatus.fromWire('SUSPENDED'), AccountStatus.suspended);
      expect(AccountStatus.fromWire('anything-else'), AccountStatus.pending);
    });
  });
}
