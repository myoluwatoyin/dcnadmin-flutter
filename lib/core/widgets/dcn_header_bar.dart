import 'package:flutter/material.dart';

import '../theme/dcn_colors.dart';
import 'dcn_icon.dart';

/// Sticky in-app header. Shows a back button (when [onBack] given) or a [left]
/// widget, a title + optional subtitle, and a [right] cluster. Gains a 1px
/// bottom border once the content beneath it has scrolled ([scrolled]).
class DcnHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const DcnHeaderBar({
    super.key,
    this.title = '',
    this.sub,
    this.onBack,
    this.left,
    this.right,
    this.scrolled = false,
  });

  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final Widget? left;
  final List<Widget>? right;
  final bool scrolled;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: scrolled ? c.border : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                child: DcnIcon('arrowLeft', size: 18, color: c.text),
              ),
            )
          else if (left != null)
            left!,
          if (onBack != null || left != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                      letterSpacing: -0.15,
                    ),
                  ),
                if (sub != null)
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.textMuted),
                  ),
              ],
            ),
          ),
          if (right != null) ...right!,
        ],
      ),
    );
  }
}
