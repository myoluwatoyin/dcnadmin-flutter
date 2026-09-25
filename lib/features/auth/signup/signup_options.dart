/// Local option sets for the signup form. Per the product brief these school
/// lists may live as local constants (no admin-managed backend source yet).
/// Departments/sub-units are NOT here — those are fetched from the backend.
class SignupOptions {
  static const genders = ['Male', 'Female'];

  static const institutions = ['University of Ibadan', 'Other'];

  static const levels = ['100', '200', '300', '400', '500', 'Postgraduate'];

  static const faculties = [
    'Agriculture & Forestry',
    'Arts',
    'Basic Medical Sciences',
    'Clinical Sciences',
    'Dentistry',
    'Education',
    'Law',
    'Pharmacy',
    'Public Health',
    'Science',
    'Social Sciences',
    'Technology',
    'Veterinary Medicine',
  ];

  static const hostels = [
    'Indy', 'Zik', 'Bello', 'Kuti', 'Mellanby', 'Tedder', 'Idia', 'Queens',
    'Awo', "St Anne's", 'ITH', 'CMF', 'AOO', 'Immanuel College Hostel',
    'Talent', 'CBN', 'Water Brooks',
  ];

  static const attendanceDurations = [
    'First time',
    'Less than 3 months',
    '3-6 months',
    '6 months - 1 year',
    'More than 1 year',
  ];

  static const churchMemberOptions = ['Yes', 'No', 'First Timer'];

  static const believersEquipOptions = ['Yes regularly', 'Sometimes', 'No'];

  static const roles = ['PASTOR', 'HOD', 'SUBHOD', 'WORKER'];

  static const agreementText =
      'I confirm that the information provided is correct and I am willing to '
      'serve faithfully in DCN.';
}
