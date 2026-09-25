import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../widgets/auth_background.dart';

/// Account-suspended block. A suspended user authenticates but is never let
/// into a dashboard — they land here and must be reinstated by an HOD/Pastor.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.dangerSoft, shape: BoxShape.circle),
                        child: DcnIcon('lock', size: 44, color: c.danger),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Account suspended',
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
                        "Your access to the DCN app has been paused. You won't be "
                        "able to sign in until you're reinstated.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.55),
                      ),
                      const SizedBox(height: 24),
                      DcnCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What to do next',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Please reach out to your HOD or the Pastor's office to "
                              "resolve this. Once they reinstate you, sign in normally.",
                              style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    DcnButton(
                      label: 'Contact my HOD',
                      size: DcnButtonSize.lg,
                      variant: DcnButtonVariant.secondary,
                      icon: 'phone',
                      full: true,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    DcnButton(
                      label: 'Back to sign in',
                      size: DcnButtonSize.lg,
                      variant: DcnButtonVariant.plain,
                      full: true,
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/');
                      },
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
