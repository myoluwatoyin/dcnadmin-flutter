import 'package:flutter/material.dart';

import '../../../core/theme/dcn_colors.dart';

/// The soft vertical-gradient auth backdrop with two blurred purple orbs,
/// ported from the prototype's `AuthBg`. Wraps every guest screen.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bgSubtle, c.bg, c.bg],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // top-right orb
          Positioned(
            top: -160,
            right: -120,
            child: _Orb(
              size: 380,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
            ),
          ),
          // bottom-left orb
          Positioned(
            bottom: -200,
            left: -100,
            child: _Orb(
              size: 320,
              color: const Color(0xFFA78BFA).withValues(alpha: 0.16),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
