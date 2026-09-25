import 'package:flutter/material.dart';

import '../../core/theme/dcn_colors.dart';
import '../../core/widgets/dcn_icon.dart';

/// One entry in a persona's bottom tab bar.
class PersonaTab {
  const PersonaTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final String icon;
  final WidgetBuilder builder;
}

/// The role-aware app shell: an [IndexedStack] of tab screens with the DCN
/// bottom navigation bar (active = brand color inside a soft pill, red count
/// badge), ported 1:1 from the prototype's BottomTabs.
///
/// Controlled component: the parent owns [activeIndex] and reacts to
/// [onIndexChanged], which lets screens (e.g. Home) jump between tabs.
class PersonaScaffold extends StatelessWidget {
  const PersonaScaffold({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onIndexChanged,
    this.badges = const {},
  });

  final List<PersonaTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onIndexChanged;
  final Map<String, int> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: activeIndex,
          children: [
            for (final tab in tabs)
              // Keep each tab's state alive across switches.
              _KeepAlive(child: Builder(builder: tab.builder)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        activeIndex: activeIndex,
        badges: badges,
        onTap: onIndexChanged,
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.activeIndex,
    required this.badges,
    required this.onTap,
  });

  final List<PersonaTab> tabs;
  final int activeIndex;
  final Map<String, int> badges;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    active: i == activeIndex,
                    badge: badges[tabs[i].id] ?? 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final PersonaTab tab;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final color = active ? c.brand : c.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? c.brandSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: DcnIcon(tab.icon, size: 20, color: color),
                ),
                if (badge > 0)
                  Positioned(
                    top: -2,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14),
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.danger,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: c.surface, width: 2),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
