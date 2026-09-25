import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/storage_service.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_select_field.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../auth/signup/signup_options.dart';
import '../../worker/data/worker_providers.dart';
import '../data/fu_providers.dart';

// ── Chooser ──────────────────────────────────────────────────
class FuAddMemberScreen extends StatelessWidget {
  const FuAddMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Add a new member', sub: 'Choose how to bring them in', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: c.infoSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.info.withValues(alpha: 0.5))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DcnIcon('alertCircle', size: 18, color: c.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Members don't log in.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.info)),
                              const SizedBox(height: 2),
                              Text("You're creating a profile on their behalf. Only the follow-up team and HODs can see it.", style: TextStyle(fontSize: 12, color: c.text, height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Method(icon: 'user', tone: DcnTone.brand, label: 'Add one member', sub: 'Type their details by hand.', metric: '~ 45 sec', onTap: () => context.push('/fu/add-manual')),
                  const SizedBox(height: 12),
                  _Method(icon: 'upload', tone: DcnTone.info, label: 'Bulk import from spreadsheet', sub: 'Upload CSV or Excel; we map columns and flag duplicates.', metric: 'Up to 500 rows', onTap: () => context.push('/fu/add-bulk')),
                  const SizedBox(height: 12),
                  _Method(icon: 'refresh', tone: DcnTone.success, label: 'Auto-sync from Google Form', sub: 'First-timers fill the church form; we pull them in.', metric: 'Always on', badge: 'ON', onTap: () => context.push('/fu/add-sync')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.icon, required this.tone, required this.label, required this.sub, required this.metric, this.badge, required this.onTap});
  final String icon;
  final DcnTone tone;
  final String label;
  final String sub;
  final String metric;
  final String? badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final t = switch (tone) {
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      _ => (bg: c.brandSoft, fg: c.brand),
    };
    return DcnCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(14)), child: DcnIcon(icon, size: 22, color: t.fg)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                  if (badge != null) ...[const SizedBox(width: 8), DcnChip(label: badge!, tone: DcnTone.success, size: DcnButtonSize.sm, icon: 'check')],
                ]),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.45)),
                const SizedBox(height: 8),
                Text(metric, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: t.fg)),
              ],
            ),
          ),
          DcnIcon('chevronRight', size: 20, color: c.textDim),
        ],
      ),
    );
  }
}

// ── Manual 4-step form ───────────────────────────────────────
class FuAddManualScreen extends ConsumerStatefulWidget {
  const FuAddManualScreen({super.key});
  @override
  ConsumerState<FuAddManualScreen> createState() => _ManualState();
}

class _ManualState extends ConsumerState<FuAddManualScreen> {
  String _step = 'essentials';
  String _category = 'First-Timer';
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();
  String _school = '';
  String _faculty = '';
  String _level = '';
  final _notes = TextEditingController();
  bool _busy = false;
  String? _photoPath;

  Future<void> _pickPhoto() async {
    final path = await ref.read(storageServiceProvider).pickImage();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  static const _order = ['essentials', 'personal', 'church', 'review'];
  bool get _valid => _first.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty;

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || !_valid) return;
    setState(() => _busy = true);
    final isFt = _category == 'First-Timer';
    try {
      // Upload the member photo first (if one was chosen) so its URL lands on
      // the member doc in a single write.
      String? photoUrl;
      if (_photoPath != null) {
        final key = '${DateTime.now().millisecondsSinceEpoch}';
        photoUrl = await ref.read(storageServiceProvider).uploadMemberPhoto(uid, key, _photoPath!);
      }
      await ref.read(fuRepositoryProvider).addMember(uid, {
        'name': [_first.text.trim(), _last.text.trim()].where((s) => s.isNotEmpty).join(' '),
        if (photoUrl != null) 'photo_url': photoUrl,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'dob': _dob.text.trim(),
        'category': _category,
        'status': isFt ? 'First-Timer' : 'Active',
        'weeks_absent': 0,
        'last_attended': 'Today',
        'school': _school,
        'faculty': _faculty,
        'level': _level,
        'address': _address.text.trim(),
        'first_seen': 'Today',
        'unreachable': false,
        'pipeline_status': isFt ? 'Contacted' : '',
        'week_number': isFt ? 1 : 0,
        'in_queue': isFt,
        'queue_priority': 'med',
        'queue_reason': isFt ? 'First-timer welcome call' : '',
        'queue_status': 'PENDING',
        'attendance': <bool>[],
        'follow_up_notes': _notes.text.trim().isEmpty
            ? <Map<String, dynamic>>[]
            : [
                {'from': ref.read(authStateProvider).valueOrNull?.fullName ?? 'You', 'at': 'On intake', 'body': _notes.text.trim()},
              ],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added · assigned to you'), behavior: SnackBarBehavior.floating));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add member. Try again.'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'New member', sub: 'Manual entry', onBack: () => context.pop()),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DcnSegmented(
                small: true,
                options: const [(id: 'essentials', label: '1. Basic'), (id: 'personal', label: '2. Personal'), (id: 'church', label: '3. Church'), (id: 'review', label: '4. Review')],
                value: _step,
                onChanged: (v) => setState(() => _step = v),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: switch (_step) {
                  'essentials' => _essentials(c),
                  'personal' => _personal(),
                  'church' => _church(),
                  _ => _review(c),
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  if (_step != 'essentials')
                    DcnButton(label: 'Back', variant: DcnButtonVariant.ghost, onPressed: () => setState(() => _step = _order[_order.indexOf(_step) - 1])),
                  if (_step != 'essentials') const SizedBox(width: 10),
                  Expanded(
                    child: _step != 'review'
                        ? DcnButton(
                            label: 'Continue',
                            icon: 'arrowRight',
                            full: true,
                            onPressed: (_step == 'essentials' && !_valid) ? null : () => setState(() => _step = _order[_order.indexOf(_step) + 1]),
                          )
                        : DcnButton(label: 'Save member', icon: 'check', full: true, loading: _busy, onPressed: _valid && !_busy ? _save : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _essentials(DcnColors c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Just the basics — only name and phone are required.', style: TextStyle(fontSize: 13, color: c.textMuted)),
          const SizedBox(height: 14),
          Text('This person is a…', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final cat in const [(id: 'First-Timer', icon: 'star', desc: 'Came for the first time'), (id: 'Member', icon: 'checkCircle', desc: 'Established attendee')])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: cat.id == 'First-Timer' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _category == cat.id ? c.brandSoft : c.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _category == cat.id ? c.brand : c.border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DcnIcon(cat.icon, size: 18, color: _category == cat.id ? c.brand : c.textMuted),
                            const SizedBox(height: 6),
                            Text(cat.id, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _category == cat.id ? c.brandInk : c.text)),
                            Text(cat.desc, style: TextStyle(fontSize: 11, color: c.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: DcnField(label: 'First name *', controller: _first, placeholder: 'First', onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: DcnField(label: 'Last name', controller: _last, placeholder: 'Last')),
          ]),
          const SizedBox(height: 14),
          DcnField(label: 'Phone number *', controller: _phone, icon: 'phone', placeholder: '+234 ...', keyboardType: TextInputType.phone, hint: 'Required — used for reminders, birthday SMS and follow-up.', onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          DcnField(label: 'Email', controller: _email, icon: 'user', placeholder: 'email@example.com', keyboardType: TextInputType.emailAddress),
        ],
      );

  Widget _personal() => Column(
        children: [
          DcnField(label: 'Date of birth', controller: _dob, icon: 'cake', placeholder: 'DD / MM / YYYY', hint: 'Used by the birthday SMS engine.'),
          const SizedBox(height: 14),
          DcnField(label: 'Home address', controller: _address, icon: 'location', placeholder: 'Street, area, city', multiline: true),
        ],
      );

  Widget _church() => Column(
        children: [
          DcnSelectField(label: 'School', value: _school.isEmpty ? null : _school, options: SignupOptions.institutions, icon: 'school', onChanged: (v) => setState(() => _school = v)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: DcnSelectField(label: 'Faculty', value: _faculty.isEmpty ? null : _faculty, options: SignupOptions.faculties, onChanged: (v) => setState(() => _faculty = v))),
            const SizedBox(width: 12),
            Expanded(child: DcnSelectField(label: 'Level', value: _level.isEmpty ? null : _level, options: SignupOptions.levels, onChanged: (v) => setState(() => _level = v))),
          ]),
          const SizedBox(height: 14),
          DcnField(label: 'Notes', controller: _notes, placeholder: 'Anything the follow-up team should know…', multiline: true),
        ],
      );

  Widget _review(DcnColors c) {
    final name = [_first.text.trim(), _last.text.trim()].where((s) => s.isNotEmpty).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcnCard(
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: _photoPath != null
                    ? ClipOval(
                        child: Image.file(File(_photoPath!), width: 56, height: 56, fit: BoxFit.cover),
                      )
                    : Stack(
                        children: [
                          DcnAvatar(name: name.isEmpty ? '?' : name, size: 56),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.brand,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.surface, width: 2),
                              ),
                              child: const DcnIcon('camera', size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? '—' : name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                    Text(_phone.text.isEmpty ? 'No phone' : _phone.text, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                    const SizedBox(height: 8),
                    DcnChip(label: _category, tone: _category == 'First-Timer' ? DcnTone.info : DcnTone.success, icon: _category == 'First-Timer' ? 'star' : 'checkCircle', size: DcnButtonSize.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcnIcon('alertCircle', size: 18, color: c.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What happens next', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.brandInk)),
                    const SizedBox(height: 3),
                    Text(
                      _category == 'First-Timer'
                          ? "They'll be added to your follow-up queue this week and get a welcome SMS."
                          : "They'll appear in your members list and start receiving birthday / absence alerts.",
                      style: TextStyle(fontSize: 12, color: c.text, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bulk / Sync (informational) ──────────────────────────────
class FuAddInfoScreen extends StatelessWidget {
  const FuAddInfoScreen({super.key, required this.bulk});
  final bool bulk;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: bulk ? 'Bulk import' : 'Google Form sync', onBack: () => context.pop()),
            Expanded(
              child: Center(
                child: DcnEmptyState(
                  icon: bulk ? 'upload' : 'refresh',
                  title: bulk ? 'Spreadsheet import' : 'Auto-sync from Google Form',
                  body: bulk
                      ? 'Upload a CSV/Excel of members; the system maps columns and flags duplicates. Wiring the file parser + duplicate detection is a backend step coming next.'
                      : 'First-timers who fill the church Google Form are pulled in automatically. Connecting the form webhook is a backend step coming next.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
