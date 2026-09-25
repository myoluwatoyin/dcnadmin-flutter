import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/pending_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/suspended_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/chat/screens/chat_group_new_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_new_screen.dart';
import '../features/chat/screens/chat_thread_screen.dart';
import '../features/followup/screens/fu_add_member_screen.dart';
import '../features/followup/screens/fu_attendance_screen.dart';
import '../features/followup/screens/fu_birthdays_screen.dart';
import '../features/followup/screens/fu_first_timers_screen.dart';
import '../features/followup/screens/fu_hod_assign_screen.dart';
import '../features/followup/screens/fu_hod_members_screen.dart';
import '../features/followup/screens/fu_hod_shell.dart';
import '../features/followup/screens/fu_hod_sms_screen.dart';
import '../features/followup/screens/fu_hod_workers_screen.dart';
import '../features/followup/screens/fu_member_detail_screen.dart';
import '../features/followup/screens/fu_queue_screen.dart';
import '../features/followup/screens/fu_shell.dart';
import '../features/followup/screens/fu_sms_screen.dart';
import '../features/home/persona_home_screen.dart';
import '../features/pastor/screens/pastor_access_keys_screen.dart';
import '../features/pastor/screens/pastor_admin_screens.dart';
import '../features/pastor/screens/pastor_analytics_screen.dart';
import '../features/pastor/screens/pastor_departments_screen.dart';
import '../features/pastor/screens/pastor_monitor_screen.dart';
import '../features/pastor/screens/pastor_people_screen.dart';
import '../features/pastor/screens/pastor_shell.dart';
import '../features/pastor/screens/pastor_worker_detail_screen.dart';
import '../features/hod/screens/hod_accountability_screen.dart';
import '../features/hod/screens/hod_approvals_screen.dart';
import '../features/hod/screens/hod_assign_task_screen.dart';
import '../features/hod/screens/hod_dept_blast_screen.dart';
import '../features/hod/screens/hod_life_inbox_screen.dart';
import '../features/hod/screens/hod_meeting_detail_screen.dart';
import '../features/hod/screens/hod_meeting_forms.dart';
import '../features/hod/screens/hod_review_task_screen.dart';
import '../features/hod/screens/hod_scorecard_entry_screen.dart';
import '../features/hod/screens/hod_scorecards_screen.dart';
import '../features/hod/screens/hod_shell.dart';
import '../features/hod/screens/hod_subunits_screen.dart';
import '../features/hod/screens/hod_worker_detail_screen.dart';
import '../features/worker/screens/worker_accountability_screen.dart';
import '../features/worker/screens/worker_followups_screen.dart';
import '../features/worker/screens/worker_life_screen.dart';
import '../features/worker/screens/worker_meeting_detail_screen.dart';
import '../features/worker/screens/worker_notifications_screen.dart';
import '../features/worker/screens/worker_profile_screen.dart';
import '../features/worker/screens/worker_scorecards_screen.dart';
import '../features/worker/screens/worker_settings_screen.dart';
import '../features/worker/screens/worker_shell.dart';
import '../features/worker/screens/worker_task_detail_screen.dart';
import '../models/app_user.dart';
import '../models/enums.dart';

/// Root navigator key — lets non-widget code (e.g. push-notification taps)
/// navigate through the same router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App router with an auth-aware redirect driven by [authStateProvider].
///
/// - Signed out: guest routes only (splash/login/signup/pending).
/// - Signed in + approved: routed to the persona home.
/// - Signed in + suspended: locked to the suspended screen.
final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild routing whenever auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      // Wait for the first auth resolution before redirecting.
      if (auth.isLoading || auth.hasError) return null;

      final AppUser? user = auth.valueOrNull;
      final loc = state.matchedLocation;
      const guestRoutes = {'/', '/login', '/signup', '/pending'};

      if (user == null) {
        return guestRoutes.contains(loc) ? null : '/';
      }
      if (user.status == AccountStatus.suspended) {
        return loc == '/suspended' ? null : '/suspended';
      }
      // Approved & signed in — keep out of the guest funnel.
      if (guestRoutes.contains(loc) || loc == '/suspended') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LoginScreen(prefillMemberId: extra?['member_id'] as String?);
        },
      ),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/pending',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PendingScreen(
            applicationId: extra?['application_id'] as String?,
            departmentName: extra?['department'] as String?,
            approverName: extra?['approver'] as String?,
          );
        },
      ),
      GoRoute(path: '/suspended', builder: (_, __) => const SuspendedScreen()),
      GoRoute(
        path: '/home',
        builder: (context, __) {
          // Route to the persona shell. Worker is built; the other personas
          // land on the placeholder home until their dashboards ship.
          final persona = ProviderScope.containerOf(context)
              .read(authStateProvider)
              .valueOrNull
              ?.persona;
          return switch (persona) {
            Persona.worker => const WorkerShell(),
            Persona.hod => const HodShell(),
            Persona.followupWorker => const FuShell(),
            Persona.followupHod => const FuHodShell(),
            Persona.pastor => const PastorShell(),
            null => const PersonaHomeScreen(),
          };
        },
      ),
      // Pastor / Super-Admin detail routes.
      GoRoute(path: '/p/dept/:code', builder: (_, s) => PastorDeptDetailScreen(code: s.pathParameters['code']!)),
      GoRoute(path: '/p/worker/:uid', builder: (_, s) => PastorWorkerDetailScreen(uid: s.pathParameters['uid']!)),
      GoRoute(path: '/p/approvals', builder: (_, __) => const PastorApprovalsScreen()),
      GoRoute(path: '/p/access-keys', builder: (_, __) => const PastorAccessKeysScreen()),
      GoRoute(path: '/p/attendance', builder: (_, __) => const PastorAttendanceScreen()),
      GoRoute(path: '/p/scorecards', builder: (_, __) => const PastorScorecardAnalyticsScreen()),
      GoRoute(path: '/p/followup', builder: (_, __) => const PastorFollowupMonitorScreen()),
      GoRoute(path: '/p/sms', builder: (_, __) => const PastorSmsDashboardScreen()),
      GoRoute(path: '/p/life', builder: (_, __) => const PastorLifeInboxScreen()),
      GoRoute(path: '/p/settings', builder: (_, __) => const PastorSettingsScreen()),
      // Follow-Up HOD detail routes.
      GoRoute(path: '/fh/worker/:uid', builder: (_, s) => FuHodWorkerDetailScreen(uid: s.pathParameters['uid']!)),
      GoRoute(path: '/fh/absence', builder: (_, __) => const FuHodAbsenceScreen()),
      GoRoute(path: '/fh/unreachable', builder: (_, __) => const FuHodUnreachableScreen()),
      GoRoute(
        path: '/fh/assign',
        builder: (_, s) => FuHodAssignScreen(
          presetMember: s.uri.queryParameters['member'],
          presetWorker: s.uri.queryParameters['worker'],
        ),
      ),
      GoRoute(path: '/fh/sms-rules', builder: (_, __) => const FuHodSmsRulesScreen()),
      GoRoute(path: '/fh/sms-templates', builder: (_, __) => const FuHodSmsTemplatesScreen()),
      GoRoute(path: '/fh/sms-log', builder: (_, __) => const FuHodSmsLogScreen()),
      GoRoute(path: '/fh/sms-blast', builder: (_, __) => const FuHodSmsBlastScreen()),
      // Follow-Up worker detail routes.
      GoRoute(path: '/fu/queue', builder: (_, __) => const FuQueueScreen()),
      GoRoute(path: '/fu/member/:id', builder: (_, s) => FuMemberDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/fu/attendance/:service', builder: (_, s) => FuAttendanceScreen(service: s.pathParameters['service']!)),
      GoRoute(path: '/fu/birthdays', builder: (_, __) => const FuBirthdaysScreen()),
      GoRoute(path: '/fu/first-timers', builder: (_, __) => const FuFirstTimersScreen()),
      GoRoute(path: '/fu/sms', builder: (_, __) => const FuSmsScreen()),
      GoRoute(path: '/fu/add-member', builder: (_, __) => const FuAddMemberScreen()),
      GoRoute(path: '/fu/add-manual', builder: (_, __) => const FuAddManualScreen()),
      GoRoute(path: '/fu/add-bulk', builder: (_, __) => const FuAddInfoScreen(bulk: true)),
      GoRoute(path: '/fu/add-sync', builder: (_, __) => const FuAddInfoScreen(bulk: false)),
      // HOD detail routes.
      GoRoute(path: '/hod/worker/:uid', builder: (_, s) => HodWorkerDetailScreen(uid: s.pathParameters['uid']!)),
      GoRoute(path: '/hod/review/:id', builder: (_, s) => HodReviewTaskScreen(taskId: s.pathParameters['id']!)),
      GoRoute(path: '/hod/assign', builder: (_, s) => HodAssignTaskScreen(presetWorker: s.uri.queryParameters['worker'])),
      GoRoute(path: '/hod/meeting/:id', builder: (_, s) => HodMeetingDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/hod/new-meeting', builder: (_, __) => const HodNewMeetingScreen()),
      GoRoute(path: '/hod/reschedule/:id', builder: (_, s) => HodRescheduleScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/hod/cancel/:id', builder: (_, s) => HodCancelMeetingScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/hod/approvals', builder: (_, __) => const HodApprovalsScreen()),
      GoRoute(path: '/hod/scorecards', builder: (_, __) => const HodScorecardsScreen()),
      GoRoute(path: '/hod/scorecard-entry/:uid', builder: (_, s) => HodScorecardEntryScreen(uid: s.pathParameters['uid']!)),
      GoRoute(path: '/hod/accountability', builder: (_, __) => const HodAccountabilityScreen()),
      GoRoute(path: '/hod/subunits', builder: (_, __) => const HodSubUnitsScreen()),
      GoRoute(path: '/hod/blast', builder: (_, __) => const HodDeptBlastScreen()),
      GoRoute(path: '/hod/life-inbox', builder: (_, __) => const HodLifeInboxScreen()),
      // Detail screens push over the shell (they hide the bottom tab bar).
      GoRoute(
        path: '/task/:id',
        builder: (_, state) =>
            WorkerTaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/meeting/:id',
        builder: (_, state) =>
            WorkerMeetingDetailScreen(meetingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const WorkerNotificationsScreen(),
      ),
      GoRoute(
        path: '/followups',
        builder: (_, __) => const WorkerFollowupsScreen(),
      ),
      GoRoute(
        path: '/followup/:id',
        builder: (_, state) =>
            WorkerFollowupDetailScreen(id: state.pathParameters['id']!),
      ),
      // Chat / messaging (all personas).
      GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
      GoRoute(path: '/chat/new', builder: (_, __) => const ChatNewScreen()),
      GoRoute(path: '/chat/group/new', builder: (_, __) => const ChatGroupNewScreen()),
      GoRoute(
        path: '/chat/thread/:id',
        builder: (_, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return ChatThreadScreen(
            convId: s.pathParameters['id']!,
            title: extra?['title'] as String?,
          );
        },
      ),
      GoRoute(path: '/life', builder: (_, __) => const WorkerLifeScreen()),
      GoRoute(path: '/scorecards', builder: (_, __) => const WorkerScorecardsScreen()),
      GoRoute(path: '/accountability', builder: (_, __) => const WorkerAccountabilityScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const WorkerProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const WorkerSettingsScreen()),
    ],
  );
});
