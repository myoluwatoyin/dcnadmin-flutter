import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/functions_service.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../signup/signup_draft_store.dart';
import '../widgets/auth_background.dart';

/// Approval-pending state shown after a signup application is submitted. Signup
/// does NOT sign the user in — it explains the application is awaiting HOD/
/// Pastor review and lets the applicant check their status (revealing the
/// minted member ID once approved), then routes them to sign in.
class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({
    super.key,
    this.applicationId,
    this.submittedAt,
    this.departmentName,
    this.approverName,
  });

  final String? applicationId;
  final String? submittedAt;
  final String? departmentName;
  final String? approverName;

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  bool _checking = false;
  String? _error;

  /// One of: null (pending, not yet checked or still pending), 'APPROVED',
  /// 'REJECTED'.
  String? _status;
  String? _memberId;
  String? _reason;

  Future<String?> _resolveAppId() async {
    return widget.applicationId ??
        await ref.read(signupDraftStoreProvider).readApplicationId();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final appId = await _resolveAppId();
      if (appId == null) {
        setState(() {
          _checking = false;
          _error = 'We could not find your application on this device. '
              'Please sign in once approved.';
        });
        return;
      }
      final res = await ref.read(functionsServiceProvider).checkApplicationStatus(appId);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _status = res.status;
        _memberId = res.memberId;
        _reason = res.reason;
      });
    } on FunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = 'Could not check your status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    if (_status == 'APPROVED') return _buildApproved(context, c);
    if (_status == 'REJECTED') return _buildRejected(context, c);
    return _buildPending(context, c);
  }

  Widget _buildPending(BuildContext context, DcnColors c) {
    final reviewSub = [widget.departmentName, widget.approverName]
        .where((s) => (s ?? '').isNotEmpty)
        .join(' · ');
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
                  child: Column(
                    children: [
                      _PulseCircle(
                        color: c.warning,
                        soft: c.warningSoft,
                        icon: 'clock',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "You're on the list!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your application is with your HOD. We'll text you the moment "
                        "you're approved — usually within 24 hours.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.55),
                      ),
                      const SizedBox(height: 32),
                      _TimelineCard(
                        icon: 'checkCircle',
                        iconColor: c.success,
                        title: 'Application submitted',
                        sub: widget.submittedAt ?? 'Just now',
                      ),
                      const SizedBox(height: 12),
                      _TimelineCard(
                        leading: _RingDot(color: c.warning, filled: true),
                        title: 'Awaiting HOD review',
                        sub: reviewSub.isNotEmpty ? reviewSub : 'Your department HOD',
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: 0.5,
                        child: _TimelineCard(
                          leading: _RingDot(color: c.border, filled: false),
                          title: 'Welcome & setup',
                          sub: 'Once approved',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: c.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    DcnButton(
                      label: _checking ? 'Checking…' : 'Check approval status',
                      size: DcnButtonSize.lg,
                      full: true,
                      onPressed: _checking ? null : _checkStatus,
                    ),
                    const SizedBox(height: 8),
                    DcnButton(
                      label: 'Back to sign in',
                      size: DcnButtonSize.lg,
                      variant: DcnButtonVariant.plain,
                      full: true,
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApproved(BuildContext context, DcnColors c) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
                  child: Column(
                    children: [
                      _PulseCircle(color: c.success, soft: c.successSoft, icon: 'checkCircle'),
                      const SizedBox(height: 24),
                      Text(
                        "You're approved!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in with your Member ID and the password you chose.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.55),
                      ),
                      const SizedBox(height: 28),
                      DcnCard(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'YOUR MEMBER ID',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: c.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _memberId ?? '—',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: c.brand,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: DcnButton(
                  label: 'Continue to sign in',
                  size: DcnButtonSize.lg,
                  full: true,
                  onPressed: () async {
                    await ref.read(signupDraftStoreProvider).clear();
                    if (!context.mounted) return;
                    context.go('/login', extra: {'member_id': _memberId});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejected(BuildContext context, DcnColors c) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
                  child: Column(
                    children: [
                      _PulseCircle(color: c.danger, soft: c.dangerSoft, icon: 'xCircle'),
                      const SizedBox(height: 24),
                      Text(
                        'Application not approved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (_reason == null || _reason!.isEmpty)
                            ? 'Your HOD was unable to approve this application. '
                                'Please reach out to your department lead for details.'
                            : _reason!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: DcnButton(
                  label: 'Back to sign in',
                  size: DcnButtonSize.lg,
                  variant: DcnButtonVariant.plain,
                  full: true,
                  onPressed: () async {
                    await ref.read(signupDraftStoreProvider).clear();
                    if (!context.mounted) return;
                    context.go('/');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  const _PulseCircle({required this.color, required this.soft, required this.icon});
  final Color color;
  final Color soft;
  final String icon;

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 100,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: widget.soft, shape: BoxShape.circle),
        child: DcnIcon(widget.icon, size: 44, color: widget.color),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    required this.sub,
  });

  final String? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          leading ?? DcnIcon(icon!, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                ),
                Text(sub, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingDot extends StatelessWidget {
  const _RingDot({required this.color, required this.filled});
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: filled
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
