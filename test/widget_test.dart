import 'package:dcnadmin/features/auth/signup/signup_draft.dart';
import 'package:flutter_test/flutter_test.dart';

// Validation is centralized on SignupDraft; these guard the per-step rules the
// UI relies on. Widget/integration tests come with the dashboards.
void main() {
  group('SignupDraft validation', () {
    test('step 1 requires core identity fields and a valid email', () {
      final d = SignupDraft();
      expect(d.validateStep(1), isNotNull);
      d
        ..firstName = 'Ada'
        ..lastName = 'Obi'
        ..gender = 'Female'
        ..dateOfBirth = '01/01/2000'
        ..phoneNumber = '+2348100000000'
        ..email = 'not-an-email';
      expect(d.validateStep(1), 'Enter a valid email address.');
      d.email = 'ada@example.com';
      expect(d.validateStep(1), isNull);
    });

    test('non-student branch requires occupation and address fields', () {
      final d = SignupDraft()..isStudent = false;
      expect(d.validateStep(2), 'Occupation is required.');
    });

    test('security step enforces password policy and agreement', () {
      final d = SignupDraft()
        ..role = 'WORKER'
        ..inviteCode = 'DRAMA-1'
        ..password = 'weak'
        ..confirmPassword = 'weak';
      expect(d.validateStep(6), 'Password must be at least 8 characters.');
      d
        ..password = 'Strong1!'
        ..confirmPassword = 'Strong1!';
      expect(d.validateStep(6), 'Please accept the agreement.');
      d.agreement = true;
      expect(d.validateStep(6), isNull);
    });

    test('pastor role skips the invite code requirement', () {
      final d = SignupDraft()
        ..role = 'PASTOR'
        ..password = 'Strong1!'
        ..confirmPassword = 'Strong1!'
        ..agreement = true;
      expect(d.validateStep(6), isNull);
    });
  });
}
