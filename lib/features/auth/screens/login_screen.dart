import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_background.dart';

/// Production login: member ID + password, authenticated against the real
/// backend. No Worker/HOD/Pastor selector and no demo/biometric shortcuts —
/// the persona is derived from the backend response. Routing on success is
/// handled by the app-level redirect once the auth state updates.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.prefillMemberId});

  /// Member ID to pre-fill, e.g. after an application is approved.
  final String? prefillMemberId;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _memberId = TextEditingController();
  final _password = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillMemberId != null) {
      _memberId.text = widget.prefillMemberId!;
    }
  }

  @override
  void dispose() {
    _memberId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithMemberId(
            memberId: _memberId.text,
            password: _password.text,
          );
      // On success the auth stream updates and the router redirects. Nothing
      // else to do here.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
              DcnHeaderBar(onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue serving with DCN.',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                      const SizedBox(height: 28),
                      DcnField(
                        label: 'Member ID',
                        controller: _memberId,
                        icon: 'id',
                        placeholder: 'e.g. DCN-00421',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 14),
                      DcnField(
                        label: 'Password',
                        controller: _password,
                        icon: 'lock',
                        obscure: !_showPwd,
                        placeholder: 'Your password',
                        trailing: GestureDetector(
                          onTap: () => setState(() => _showPwd = !_showPwd),
                          child: DcnIcon(
                            _showPwd ? 'eyeOff' : 'eye',
                            size: 18,
                            color: c.textDim,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.brand,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DcnButton(
                        label: _loading ? 'Signing you in…' : 'Sign in',
                        size: DcnButtonSize.lg,
                        full: true,
                        loading: _loading,
                        onPressed: _loading ? null : _signIn,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(fontSize: 13, color: c.textMuted),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/signup'),
                              child: Text(
                                'Create one',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
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
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: c.danger, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
