import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../widgets/auth_background.dart';

/// Welcome / landing. DCN branding with two clear actions — Sign in and
/// Create new account — per the product brief.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.brand, c.brandDeep],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Text(
                          'D',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'DCN Admin',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Disciples Christian Network',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'The ministry tool for workers, HODs and pastors. '
                        'Built for the field — attendance, follow-ups, meetings, '
                        'all in one place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: c.textMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    DcnButton(
                      label: 'Sign in',
                      size: DcnButtonSize.lg,
                      full: true,
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 12),
                    DcnButton(
                      label: 'Create new account',
                      size: DcnButtonSize.lg,
                      variant: DcnButtonVariant.ghost,
                      full: true,
                      onPressed: () => context.push('/signup'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'v1.0.0 · For ministry staff only. Church members do not log in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: c.textDim),
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
}
