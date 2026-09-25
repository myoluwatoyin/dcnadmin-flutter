import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/dcn_theme.dart';
import 'router.dart';

class DcnAdminApp extends ConsumerWidget {
  const DcnAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Register/deregister this device for push as the session changes.
    ref.listen(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      final messaging = ref.read(messagingServiceProvider);
      if (user != null && user.isApproved) {
        messaging.initForUser(user.id);
      } else if (user == null) {
        messaging.clearForUser();
      }
    });
    return MaterialApp.router(
      title: 'DCN Admin',
      debugShowCheckedModeBanner: false,
      theme: DcnTheme.light(),
      darkTheme: DcnTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
