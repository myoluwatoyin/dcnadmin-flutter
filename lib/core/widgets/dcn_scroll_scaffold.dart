import 'package:flutter/material.dart';

/// A screen with a sticky header that gains its bottom border once the body has
/// scrolled past 6px, matching the prototype's scroll-shadow behavior. [header]
/// is rebuilt with the current `scrolled` flag; [child] is the scrollable body.
class DcnScrollScaffold extends StatefulWidget {
  const DcnScrollScaffold({
    super.key,
    required this.header,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  final Widget Function(bool scrolled) header;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  State<DcnScrollScaffold> createState() => _DcnScrollScaffoldState();
}

class _DcnScrollScaffoldState extends State<DcnScrollScaffold> {
  bool _scrolled = false;

  bool _onNotification(ScrollNotification n) {
    final scrolled = n.metrics.pixels > 6;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.header(_scrolled),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onNotification,
            child: SingleChildScrollView(
              controller: widget.controller,
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
