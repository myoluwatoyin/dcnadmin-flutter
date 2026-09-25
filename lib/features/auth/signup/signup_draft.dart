import '../../../models/department.dart';

/// Mutable working state for the six-step signup application. Field names match
/// the backend payload names in the product brief so mapping stays consistent.
class SignupDraft {
  // Step 1 — Identity
  String? photoPath;
  String firstName = '';
  String lastName = '';
  String otherNames = '';
  String gender = '';
  String dateOfBirth = '';
  String phoneNumber = '';
  String email = '';
  bool whatsappSameAsPhone = true;
  String whatsappNumber = '';

  // Step 2 — Student
  bool? isStudent;
  String institution = '';
  String otherInstitution = '';
  String faculty = '';
  String course = '';
  String level = '';
  String matricNumber = '';
  String hostel = '';
  String roomNumber = '';
  String occupation = '';
  String workplace = '';
  String workAddress = '';
  String homeAddress = '';
  String city = '';
  String state = '';
  String country = '';

  // Step 3 — Church
  String attendanceDuration = '';
  String isChurchMember = '';
  String attendsBelieversEquip = '';
  String invitedByText = '';
  WorkerRef? invitedByWorker;

  // Step 4 — Ministry
  Department? department;
  SubUnit? subUnit;

  // Step 5 — Responsibilities
  bool? servingAnotherChurch;
  String otherChurchName = '';
  String otherChurchRole = '';
  String additionalResponsibilities = '';
  String emergencyContactName = '';
  String emergencyContactPhone = '';
  String guardianName = '';
  String guardianPhone = '';

  // Step 6 — Security
  String role = '';
  String inviteCode = '';
  String password = '';
  String confirmPassword = '';
  bool agreement = false;

  bool get isEmailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  /// Password rules from the brief: ≥8 chars, ≥1 number, ≥1 special char.
  bool get passwordHasMinLength => password.length >= 8;
  bool get passwordHasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get passwordHasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  bool get passwordsMatch => password.isNotEmpty && password == confirmPassword;
  bool get isPastor => role == 'PASTOR';

  /// Builds the submission payload with normalized values for the backend.
  Map<String, dynamic> toPayload() {
    final effectivePhone = whatsappSameAsPhone ? phoneNumber : whatsappNumber;
    return {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'other_names': otherNames.trim(),
      'gender': gender,
      'date_of_birth': dateOfBirth.trim(),
      'phone_number': phoneNumber.trim(),
      'email': email.trim(),
      'whatsapp_same_as_phone': whatsappSameAsPhone,
      'whatsapp_number': effectivePhone.trim(),
      'is_student': isStudent ?? false,
      'institution': institution == 'Other' ? otherInstitution.trim() : institution,
      'faculty': faculty,
      'course': course.trim(),
      'level': level,
      'matric_number': matricNumber.trim(),
      'hostel': hostel,
      'room_number': roomNumber.trim(),
      'occupation': occupation.trim(),
      'workplace': workplace.trim(),
      'work_address': workAddress.trim(),
      'home_address': homeAddress.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'attendance_duration': attendanceDuration,
      'is_church_member': isChurchMember,
      'attends_believers_equip': attendsBelieversEquip,
      'invited_by_text': invitedByText.trim(),
      'invited_by_worker_id': invitedByWorker?.id,
      'invited_by_worker_name': invitedByWorker?.name,
      'department': department?.code,
      'department_id': department?.id,
      'sub_unit': subUnit?.id,
      'sub_unit_name': subUnit?.name,
      'serving_another_church': servingAnotherChurch ?? false,
      'other_church_name': otherChurchName.trim(),
      'other_church_role': otherChurchRole.trim(),
      'additional_responsibilities': additionalResponsibilities.trim(),
      'emergency_contact_name': emergencyContactName.trim(),
      'emergency_contact_phone': emergencyContactPhone.trim(),
      'guardian_name': guardianName.trim(),
      'guardian_phone': guardianPhone.trim(),
      'role': role,
    };
  }

  /// Returns an error string for [step] (1-based), or null if valid.
  String? validateStep(int step) {
    switch (step) {
      case 1:
        if (firstName.trim().isEmpty) return 'First name is required.';
        if (lastName.trim().isEmpty) return 'Last name is required.';
        if (gender.isEmpty) return 'Select your gender.';
        if (dateOfBirth.trim().isEmpty) return 'Date of birth is required.';
        if (phoneNumber.trim().isEmpty) return 'Phone number is required.';
        if (!isEmailValid) return 'Enter a valid email address.';
        if (!whatsappSameAsPhone && whatsappNumber.trim().isEmpty) {
          return 'WhatsApp number is required.';
        }
        return null;
      case 2:
        if (isStudent == null) return 'Let us know if you are a student.';
        if (isStudent == true) {
          if (institution.isEmpty) return 'Select your institution.';
          if (institution == 'Other' && otherInstitution.trim().isEmpty) {
            return 'Enter your institution name.';
          }
          if (faculty.isEmpty) return 'Select your faculty.';
          if (course.trim().isEmpty) return 'Course is required.';
          if (level.isEmpty) return 'Select your level.';
          if (hostel.isEmpty) return 'Select your hostel.';
          if (roomNumber.trim().isEmpty) return 'Room number is required.';
        } else {
          if (occupation.trim().isEmpty) return 'Occupation is required.';
          if (workplace.trim().isEmpty) return 'Workplace is required.';
          if (workAddress.trim().isEmpty) return 'Work address is required.';
          if (homeAddress.trim().isEmpty) return 'Home address is required.';
          if (city.trim().isEmpty) return 'City is required.';
          if (state.trim().isEmpty) return 'State is required.';
          if (country.trim().isEmpty) return 'Country is required.';
        }
        return null;
      case 3:
        if (attendanceDuration.isEmpty) return 'Select how long you have attended.';
        if (isChurchMember.isEmpty) return 'Select your membership status.';
        if (attendsBelieversEquip.isEmpty) {
          return 'Select your Believers Equip attendance.';
        }
        if (invitedByText.trim().isEmpty) return 'Tell us who invited you.';
        return null;
      case 4:
        if (department == null) return 'Select your department.';
        if (department!.requiresSubUnit && subUnit == null) {
          return 'This department requires a sub-unit.';
        }
        return null;
      case 5:
        if (servingAnotherChurch == null) {
          return 'Let us know if you serve in another church.';
        }
        if (servingAnotherChurch == true) {
          if (otherChurchName.trim().isEmpty) return 'Enter the other church name.';
          if (otherChurchRole.trim().isEmpty) return 'Enter your role there.';
        }
        if (emergencyContactName.trim().isEmpty) {
          return 'Emergency contact name is required.';
        }
        if (emergencyContactPhone.trim().isEmpty) {
          return 'Emergency contact phone is required.';
        }
        if (isStudent == true) {
          if (guardianName.trim().isEmpty) return 'Guardian name is required.';
          if (guardianPhone.trim().isEmpty) return 'Guardian phone is required.';
        }
        return null;
      case 6:
        if (role.isEmpty) return 'Select your role.';
        if (!isPastor && inviteCode.trim().isEmpty) {
          return 'An invite code is required.';
        }
        if (!passwordHasMinLength) return 'Password must be at least 8 characters.';
        if (!passwordHasNumber) return 'Password must contain a number.';
        if (!passwordHasSpecial) return 'Password must contain a special character.';
        if (!passwordsMatch) return 'Passwords do not match.';
        if (!agreement) return 'Please accept the agreement.';
        return null;
      default:
        return null;
    }
  }
}
