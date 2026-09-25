import 'package:flutter/material.dart';

/// Maps the prototype's (Feather/Lucide) icon names to the closest Material
/// glyph so screens can reference icons by the same string keys used in the
/// design source. Swap this mapping for a Lucide icon font later for exact
/// parity — the call sites stay unchanged.
class DcnIcon extends StatelessWidget {
  const DcnIcon(this.name, {super.key, this.size = 20, this.color});

  final String name;
  final double size;
  final Color? color;

  static const Map<String, IconData> _map = {
    'home': Icons.home_outlined,
    'check': Icons.check,
    'checkCircle': Icons.check_circle_outline,
    'x': Icons.close,
    'xCircle': Icons.cancel_outlined,
    'chevronRight': Icons.chevron_right,
    'chevronLeft': Icons.chevron_left,
    'chevronDown': Icons.keyboard_arrow_down,
    'chevronUp': Icons.keyboard_arrow_up,
    'arrowLeft': Icons.arrow_back,
    'arrowRight': Icons.arrow_forward,
    'arrowUpRight': Icons.north_east,
    'bell': Icons.notifications_none,
    'user': Icons.person_outline,
    'users': Icons.group_outlined,
    'calendar': Icons.calendar_today_outlined,
    'clipboard': Icons.assignment_outlined,
    'book': Icons.menu_book_outlined,
    'bookOpen': Icons.auto_stories_outlined,
    'phone': Icons.phone_outlined,
    'msg': Icons.chat_bubble_outline,
    'send': Icons.send_outlined,
    'plus': Icons.add,
    'minus': Icons.remove,
    'search': Icons.search,
    'filter': Icons.filter_alt_outlined,
    'settings': Icons.settings_outlined,
    'moreH': Icons.more_horiz,
    'moreV': Icons.more_vert,
    'alert': Icons.warning_amber_outlined,
    'alertCircle': Icons.error_outline,
    'clock': Icons.access_time,
    'eye': Icons.visibility_outlined,
    'eyeOff': Icons.visibility_off_outlined,
    'lock': Icons.lock_outline,
    'logout': Icons.logout,
    'map': Icons.map_outlined,
    'target': Icons.gps_fixed,
    'star': Icons.star_outline,
    'cake': Icons.cake_outlined,
    'flag': Icons.flag_outlined,
    'image': Icons.image_outlined,
    'upload': Icons.upload_outlined,
    'fingerprint': Icons.fingerprint,
    'school': Icons.school_outlined,
    'sparkle': Icons.auto_awesome_outlined,
    'play': Icons.play_arrow,
    'pause': Icons.pause,
    'refresh': Icons.refresh,
    'edit': Icons.edit_outlined,
    'mic': Icons.mic_none_outlined,
    'location': Icons.location_on_outlined,
    'camera': Icons.photo_camera_outlined,
    'trending': Icons.trending_up,
    'flame': Icons.local_fire_department_outlined,
    'award': Icons.emoji_events_outlined,
    'pin': Icons.push_pin_outlined,
    'grid': Icons.grid_view_outlined,
    'list': Icons.format_list_bulleted,
    'id': Icons.badge_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      _map[name] ?? Icons.help_outline,
      size: size,
      color: color ?? IconTheme.of(context).color,
    );
  }
}
