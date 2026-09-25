import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/functions_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_select_field.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/department.dart';
import '../widgets/auth_background.dart';
import 'signup_draft.dart';
import 'signup_draft_store.dart';
import 'signup_options.dart';
import 'signup_widgets.dart';
import 'worker_search_field.dart';

const _stepNames = [
  'Identity',
  'Student',
  'Church',
  'Ministry',
  'Responsibilities',
  'Security',
];

/// Six-step signup application. Submits a PENDING application and shows the
/// approval-pending screen — it does NOT sign the user in. Ministry data,
/// inviter search, and invite-code validation all use the real backend.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _draft = SignupDraft();
  int _step = 1;
  bool _submitting = false;
  String? _error;

  void _rebuild() => setState(() {});

  void _onBack() {
    if (_step == 1) {
      context.pop();
    } else {
      setState(() {
        _step -= 1;
        _error = null;
      });
    }
  }

  Future<void> _onNext() async {
    final err = _draft.validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);

    if (_step < 6) {
      setState(() => _step += 1);
      return;
    }
    await _submit();
  }

  Future<void> _pickSignupPhoto() async {
    // Captured locally for preview; the photo is uploaded to Storage after the
    // account is approved and the user first signs in (signup is pre-auth).
    final path = await ref.read(storageServiceProvider).pickImage();
    if (path != null && mounted) setState(() => _draft.photoPath = path);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Submit via Cloud Function: it validates the invite code, creates a
      // disabled auth account with the chosen password, and files the
      // application. The password never touches Firestore.
      final payload = {
        ..._draft.toPayload(),
        'password': _draft.password,
        'invite_code': _draft.inviteCode,
        'department_name': _draft.department?.name,
        'sub_unit_name': _draft.subUnit?.name,
      };
      final appId = await ref.read(functionsServiceProvider).submitApplication(payload);

      // Remember the application id so the pending screen can check status.
      await ref.read(signupDraftStoreProvider).saveApplicationId(appId);

      if (!mounted) return;
      context.go('/pending', extra: {
        'application_id': appId,
        'department': _draft.department?.name,
      });
    } on FunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not submit your application. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              DcnHeaderBar(
                onBack: _onBack,
                title: 'Step $_step of 6',
                sub: _stepNames[_step - 1],
              ),
              // progress dots
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    for (var i = 1; i <= 6; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? c.brand : c.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      if (i < 6) const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStep(),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _InlineError(message: _error!),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SafeArea(
                  top: false,
                  child: DcnButton(
                    label: _step == 6
                        ? (_submitting ? 'Submitting…' : 'Create account')
                        : 'Continue',
                    size: DcnButtonSize.lg,
                    full: true,
                    loading: _submitting,
                    iconRight: _step == 6 ? null : 'arrowRight',
                    onPressed: _submitting ? null : _onNext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _Step1Identity(draft: _draft, rebuild: _rebuild, onPickPhoto: _pickSignupPhoto);
      case 2:
        return _Step2Student(draft: _draft, rebuild: _rebuild);
      case 3:
        return _Step3Church(draft: _draft, rebuild: _rebuild);
      case 4:
        return _Step4Ministry(draft: _draft, rebuild: _rebuild);
      case 5:
        return _Step5Responsibilities(draft: _draft, rebuild: _rebuild);
      case 6:
        return _Step6Security(draft: _draft, rebuild: _rebuild);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcnIcon('alertCircle', size: 18, color: c.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: c.danger, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Identity ────────────────────────────────────────
class _Step1Identity extends StatelessWidget {
  const _Step1Identity({required this.draft, required this.rebuild, required this.onPickPhoto});
  final SignupDraft draft;
  final VoidCallback rebuild;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Who are you?',
          subtitle: 'Tell us your basic details so we can set up your profile.',
        ),
        const SizedBox(height: 18),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: onPickPhoto,
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brandSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.brand, width: 2, style: BorderStyle.solid),
                    image: draft.photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(draft.photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: draft.photoPath != null
                      ? null
                      : DcnIcon('camera', size: 28, color: c.brand),
                ),
              ),
              const SizedBox(height: 10),
              Text(draft.photoPath != null ? 'Change photo' : 'Add profile photo',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: DcnField(
                label: 'First name',
                value: draft.firstName,
                placeholder: 'First',
                onChanged: (v) => draft.firstName = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DcnField(
                label: 'Last name',
                value: draft.lastName,
                placeholder: 'Last',
                onChanged: (v) => draft.lastName = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Other names (optional)',
          value: draft.otherNames,
          placeholder: 'Middle / other names',
          onChanged: (v) => draft.otherNames = v,
        ),
        const SizedBox(height: 14),
        OptionPills(
          label: 'Gender',
          options: SignupOptions.genders,
          value: draft.gender.isEmpty ? null : draft.gender,
          onChanged: (v) {
            draft.gender = v;
            rebuild();
          },
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Date of birth',
          value: draft.dateOfBirth,
          placeholder: 'DD / MM / YYYY',
          icon: 'cake',
          hint: 'Used by the birthday SMS engine.',
          onChanged: (v) => draft.dateOfBirth = v,
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Phone number',
          value: draft.phoneNumber,
          placeholder: '+234 810 000 0000',
          icon: 'phone',
          keyboardType: TextInputType.phone,
          onChanged: (v) => draft.phoneNumber = v,
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Email address',
          value: draft.email,
          placeholder: 'you@example.com',
          icon: 'user',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => draft.email = v,
        ),
        const SizedBox(height: 14),
        _CheckboxRow(
          label: 'My WhatsApp number is the same as my phone number',
          value: draft.whatsappSameAsPhone,
          onChanged: (v) {
            draft.whatsappSameAsPhone = v;
            rebuild();
          },
        ),
        if (!draft.whatsappSameAsPhone) ...[
          const SizedBox(height: 14),
          DcnField(
            label: 'WhatsApp number',
            value: draft.whatsappNumber,
            placeholder: '+234 ...',
            icon: 'msg',
            keyboardType: TextInputType.phone,
            onChanged: (v) => draft.whatsappNumber = v,
          ),
        ],
      ],
    );
  }
}

// ── Step 2 — Student ─────────────────────────────────────────
class _Step2Student extends StatelessWidget {
  const _Step2Student({required this.draft, required this.rebuild});
  final SignupDraft draft;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context) {
    final isStudent = draft.isStudent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Where do you study or work?',
          subtitle: 'This helps us serve you better. Fill what applies.',
        ),
        const SizedBox(height: 18),
        OptionPills(
          label: 'Are you a student?',
          options: const ['Yes', 'No'],
          value: isStudent == null ? null : (isStudent ? 'Yes' : 'No'),
          onChanged: (v) {
            draft.isStudent = v == 'Yes';
            rebuild();
          },
        ),
        if (isStudent == true) ...[
          const SizedBox(height: 16),
          DcnSelectField(
            label: 'Institution',
            value: draft.institution.isEmpty ? null : draft.institution,
            icon: 'school',
            options: SignupOptions.institutions,
            onChanged: (v) {
              draft.institution = v;
              rebuild();
            },
          ),
          if (draft.institution == 'Other') ...[
            const SizedBox(height: 14),
            DcnField(
              label: 'Institution name',
              value: draft.otherInstitution,
              placeholder: 'Type your institution',
              onChanged: (v) => draft.otherInstitution = v,
            ),
          ],
          const SizedBox(height: 14),
          DcnSelectField(
            label: 'Faculty',
            value: draft.faculty.isEmpty ? null : draft.faculty,
            options: SignupOptions.faculties,
            onChanged: (v) {
              draft.faculty = v;
              rebuild();
            },
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Course',
            value: draft.course,
            placeholder: 'e.g. Computer Science',
            onChanged: (v) => draft.course = v,
          ),
          const SizedBox(height: 14),
          DcnSelectField(
            label: 'Level',
            value: draft.level.isEmpty ? null : draft.level,
            options: SignupOptions.levels,
            onChanged: (v) {
              draft.level = v;
              rebuild();
            },
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Matric number (optional)',
            value: draft.matricNumber,
            placeholder: 'e.g. 210591',
            onChanged: (v) => draft.matricNumber = v,
          ),
          const SizedBox(height: 14),
          DcnSelectField(
            label: 'Hostel',
            value: draft.hostel.isEmpty ? null : draft.hostel,
            options: SignupOptions.hostels,
            onChanged: (v) {
              draft.hostel = v;
              rebuild();
            },
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Room number',
            value: draft.roomNumber,
            placeholder: 'e.g. B12',
            onChanged: (v) => draft.roomNumber = v,
          ),
        ],
        if (isStudent == false) ...[
          const SizedBox(height: 16),
          DcnField(
            label: 'Occupation',
            value: draft.occupation,
            placeholder: 'e.g. Software developer',
            onChanged: (v) => draft.occupation = v,
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Workplace',
            value: draft.workplace,
            placeholder: 'Company / organisation',
            onChanged: (v) => draft.workplace = v,
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Work address',
            value: draft.workAddress,
            placeholder: 'Street, area',
            icon: 'location',
            onChanged: (v) => draft.workAddress = v,
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Home address',
            value: draft.homeAddress,
            placeholder: 'Street, area',
            icon: 'location',
            onChanged: (v) => draft.homeAddress = v,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DcnField(
                  label: 'City',
                  value: draft.city,
                  placeholder: 'City',
                  onChanged: (v) => draft.city = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DcnField(
                  label: 'State',
                  value: draft.state,
                  placeholder: 'State',
                  onChanged: (v) => draft.state = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Country',
            value: draft.country,
            placeholder: 'Country',
            onChanged: (v) => draft.country = v,
          ),
        ],
      ],
    );
  }
}

// ── Step 3 — Church ──────────────────────────────────────────
class _Step3Church extends StatelessWidget {
  const _Step3Church({required this.draft, required this.rebuild});
  final SignupDraft draft;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Your church record',
          subtitle: 'So the follow-up team can care for you well.',
        ),
        const SizedBox(height: 18),
        OptionPills(
          label: 'How long have you attended DCN?',
          options: SignupOptions.attendanceDurations,
          value: draft.attendanceDuration.isEmpty ? null : draft.attendanceDuration,
          onChanged: (v) {
            draft.attendanceDuration = v;
            rebuild();
          },
        ),
        const SizedBox(height: 16),
        OptionPills(
          label: 'Are you a church member?',
          options: SignupOptions.churchMemberOptions,
          value: draft.isChurchMember.isEmpty ? null : draft.isChurchMember,
          onChanged: (v) {
            draft.isChurchMember = v;
            rebuild();
          },
        ),
        const SizedBox(height: 16),
        OptionPills(
          label: 'Do you attend Believers Equip?',
          options: SignupOptions.believersEquipOptions,
          value: draft.attendsBelieversEquip.isEmpty ? null : draft.attendsBelieversEquip,
          onChanged: (v) {
            draft.attendsBelieversEquip = v;
            rebuild();
          },
        ),
        const SizedBox(height: 16),
        DcnField(
          label: 'Who invited you? (name)',
          value: draft.invitedByText,
          placeholder: "The person who brought you",
          icon: 'user',
          onChanged: (v) => draft.invitedByText = v,
        ),
        const SizedBox(height: 14),
        WorkerSearchField(
          label: 'Link the worker who invited you (optional)',
          selected: draft.invitedByWorker,
          onSelected: (w) {
            draft.invitedByWorker = w;
            rebuild();
          },
        ),
        const SizedBox(height: 16),
        const InfoCallout(
          title: 'Your data stays inside DCN',
          body: 'Only your HOD and the Follow-Up team can see your contact information.',
        ),
      ],
    );
  }
}

// ── Step 4 — Ministry (real departments) ─────────────────────
class _Step4Ministry extends ConsumerWidget {
  const _Step4Ministry({required this.draft, required this.rebuild});
  final SignupDraft draft;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final async = ref.watch(departmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Which department?',
          subtitle: 'Pick the department you are joining as a worker.',
        ),
        const SizedBox(height: 18),
        async.when(
          loading: () => const _DeptSkeleton(),
          error: (e, _) => _RetryBox(
            message: 'Could not load departments.',
            onRetry: () => ref.invalidate(departmentsProvider),
          ),
          data: (departments) {
            if (departments.isEmpty) {
              return _RetryBox(
                message: 'No departments available yet.',
                onRetry: () => ref.invalidate(departmentsProvider),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    for (final d in departments)
                      _DeptCard(
                        dept: d,
                        active: draft.department?.id == d.id,
                        onTap: () {
                          draft.department = d;
                          if (draft.subUnit != null &&
                              !d.subUnits.any((s) => s.id == draft.subUnit!.id)) {
                            draft.subUnit = null;
                          }
                          rebuild();
                        },
                      ),
                  ],
                ),
                if (draft.department != null && draft.department!.subUnits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DcnSelectField(
                    label: draft.department!.requiresSubUnit
                        ? 'Sub-unit'
                        : 'Sub-unit (optional)',
                    value: draft.subUnit?.name,
                    options: draft.department!.subUnits.map((s) => s.name).toList(),
                    onChanged: (name) {
                      draft.subUnit = draft.department!.subUnits
                          .firstWhere((s) => s.name == name);
                      rebuild();
                    },
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Your invite/access code will be checked in the last step.',
            style: TextStyle(fontSize: 12, color: c.textDim),
          ),
        ),
      ],
    );
  }
}

class _DeptCard extends StatelessWidget {
  const _DeptCard({required this.dept, required this.active, required this.onTap});
  final Department dept;
  final bool active;
  final VoidCallback onTap;

  static const _iconByCode = {
    'WORSHIP': 'mic',
    'MEDIA': 'camera',
    'USHERING': 'users',
    'DRAMA': 'star',
    'TECHNICAL': 'settings',
    'FOLLOWUP': 'phone',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final iconName = _iconByCode[dept.code.toUpperCase()] ?? 'users';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? c.brand : c.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.brand : c.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DcnIcon(iconName, size: 20, color: active ? Colors.white : c.brand),
            ),
            const SizedBox(height: 6),
            Text(dept.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
          ],
        ),
      ),
    );
  }
}

class _DeptSkeleton extends StatelessWidget {
  const _DeptSkeleton();
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _RetryBox extends StatelessWidget {
  const _RetryBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      child: Column(
        children: [
          Text(message, style: TextStyle(fontSize: 14, color: c.textMuted)),
          const SizedBox(height: 12),
          DcnButton(
            label: 'Retry',
            size: DcnButtonSize.sm,
            variant: DcnButtonVariant.secondary,
            icon: 'refresh',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ── Step 5 — Responsibilities ────────────────────────────────
class _Step5Responsibilities extends StatelessWidget {
  const _Step5Responsibilities({required this.draft, required this.rebuild});
  final SignupDraft draft;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Responsibilities & contacts',
          subtitle: 'A few details for accountability and emergencies.',
        ),
        const SizedBox(height: 18),
        OptionPills(
          label: 'Do you serve in another church?',
          options: const ['Yes', 'No'],
          value: draft.servingAnotherChurch == null
              ? null
              : (draft.servingAnotherChurch! ? 'Yes' : 'No'),
          onChanged: (v) {
            draft.servingAnotherChurch = v == 'Yes';
            rebuild();
          },
        ),
        if (draft.servingAnotherChurch == true) ...[
          const SizedBox(height: 14),
          DcnField(
            label: 'Other church name',
            value: draft.otherChurchName,
            placeholder: 'Church name',
            onChanged: (v) => draft.otherChurchName = v,
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Your role there',
            value: draft.otherChurchRole,
            placeholder: 'e.g. Chorister',
            onChanged: (v) => draft.otherChurchRole = v,
          ),
        ],
        const SizedBox(height: 14),
        DcnField(
          label: 'Additional responsibilities (optional)',
          value: draft.additionalResponsibilities,
          placeholder: 'Anything else you help with',
          multiline: true,
          onChanged: (v) => draft.additionalResponsibilities = v,
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Emergency contact name',
          value: draft.emergencyContactName,
          placeholder: 'Full name',
          icon: 'user',
          onChanged: (v) => draft.emergencyContactName = v,
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Emergency contact phone',
          value: draft.emergencyContactPhone,
          placeholder: '+234 ...',
          icon: 'phone',
          keyboardType: TextInputType.phone,
          onChanged: (v) => draft.emergencyContactPhone = v,
        ),
        if (draft.isStudent == true) ...[
          const SizedBox(height: 14),
          DcnField(
            label: 'Guardian name',
            value: draft.guardianName,
            placeholder: 'Full name',
            icon: 'user',
            onChanged: (v) => draft.guardianName = v,
          ),
          const SizedBox(height: 14),
          DcnField(
            label: 'Guardian phone',
            value: draft.guardianPhone,
            placeholder: '+234 ...',
            icon: 'phone',
            keyboardType: TextInputType.phone,
            onChanged: (v) => draft.guardianPhone = v,
          ),
        ],
      ],
    );
  }
}

// ── Step 6 — Security ────────────────────────────────────────
class _Step6Security extends StatelessWidget {
  const _Step6Security({required this.draft, required this.rebuild});
  final SignupDraft draft;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final rules = [
      (ok: draft.passwordHasMinLength, label: 'At least 8 characters'),
      (ok: draft.passwordHasNumber, label: 'One number'),
      (ok: draft.passwordHasSpecial, label: 'One special character'),
      (ok: draft.passwordsMatch, label: 'Passwords match'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeading(
          title: 'Role & security',
          subtitle: "You'll use this password to sign in once approved.",
        ),
        const SizedBox(height: 18),
        OptionPills(
          label: 'What role are you applying for?',
          options: SignupOptions.roles,
          value: draft.role.isEmpty ? null : draft.role,
          onChanged: (v) {
            draft.role = v;
            rebuild();
          },
        ),
        if (!draft.isPastor) ...[
          const SizedBox(height: 14),
          DcnField(
            label: 'Invite code',
            value: draft.inviteCode,
            placeholder: 'e.g. DRAMA-9F2K-44XQ',
            icon: 'lock',
            hint: 'Provided by your HOD. Validated when you submit.',
            onChanged: (v) => draft.inviteCode = v,
          ),
        ],
        const SizedBox(height: 14),
        DcnField(
          label: 'Password',
          value: draft.password,
          placeholder: 'Create a password',
          icon: 'lock',
          obscure: true,
          onChanged: (v) {
            draft.password = v;
            rebuild();
          },
        ),
        const SizedBox(height: 14),
        DcnField(
          label: 'Confirm password',
          value: draft.confirmPassword,
          placeholder: 'Re-enter password',
          icon: 'lock',
          obscure: true,
          onChanged: (v) {
            draft.confirmPassword = v;
            rebuild();
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      DcnIcon(r.ok ? 'checkCircle' : 'xCircle',
                          size: 15, color: r.ok ? c.success : c.textDim),
                      const SizedBox(width: 8),
                      Text(r.label,
                          style: TextStyle(
                              fontSize: 12.5, color: r.ok ? c.text : c.textMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CheckboxRow(
          label: SignupOptions.agreementText,
          value: draft.agreement,
          onChanged: (v) {
            draft.agreement = v;
            rebuild();
          },
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? c.brand : c.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: value ? c.brand : c.border, width: 1.5),
            ),
            child: value
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
