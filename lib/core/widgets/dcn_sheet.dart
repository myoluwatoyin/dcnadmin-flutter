import 'package:flutter/material.dart';

import '../theme/dcn_colors.dart';
import 'dcn_icon.dart';

/// Presents a DCN-styled modal bottom sheet: rounded 24 top corners, a drag
/// handle, an optional title row with a close button. The prototype uses bottom
/// sheets for every secondary flow — never centered dialogs.
Future<T?> showDcnSheet<T>({
  required BuildContext context,
  String? title,
  required WidgetBuilder builder,
}) {
  final c = context.dcn;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                            child: DcnIcon('x', size: 18, color: c.textMuted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: builder(ctx),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
