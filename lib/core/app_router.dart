import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:irs_admin/views/complaints/complaint_details_page.dart';
import 'package:irs_admin/views/complaints/view_complaints_page.dart';
import 'package:irs_admin/views/dashboard_view.dart';
import 'package:irs_admin/views/forgot_password_view.dart';
import 'package:irs_admin/views/login_view.dart';
import 'package:irs_admin/views/news/news_page.dart';
import 'package:irs_admin/views/news/update_news_page.dart';
import 'package:irs_admin/views/reconciliation/schedule_meeting_page.dart';
import 'package:irs_admin/views/reports/add_incident_page.dart';
import 'package:irs_admin/views/reports/incident_details_page.dart';
import 'package:irs_admin/views/reports/view_incidents_page.dart';
import 'package:irs_admin/views/sos/sos_details_page.dart';
import 'package:irs_admin/views/sos/view_sos_page.dart';
import 'package:irs_admin/views/users/update_user_view.dart';
import 'package:irs_admin/views/users/users_view.dart';

import 'navigation_menu.dart';

class AppRouter {
  AppRouter._();

  static String initR = "/login";

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final _rootNavigatorDashboard =
      GlobalKey<NavigatorState>(debugLabel: "shellDashboard");
  static final _rootNavigatorReports =
      GlobalKey<NavigatorState>(debugLabel: "shellReports");
      static final _rootNavigatorSOS =
      GlobalKey<NavigatorState>(debugLabel: "shellSOS");
  static final _rootNavigatorUsers =
      GlobalKey<NavigatorState>(debugLabel: "shellUsers");
  static final _rootNavigatorNews =
      GlobalKey<NavigatorState>(debugLabel: "shellNews");
  static final _rootNavigatorComplaints =
      GlobalKey<NavigatorState>(debugLabel: "shellComplaints");
  // static final _rootNavigatorSchedule =
  //     GlobalKey<NavigatorState>(debugLabel: "shellSchedule");

  static final GoRouter router = GoRouter(
    initialLocation: initR,
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final FirebaseAuth _auth = FirebaseAuth.instance;

      final currentUser = _auth.currentUser;

      if (currentUser == null &&
          state.uri.path != '/login' &&
          state.uri.path != '/forgot-password') {
        return '/login';
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return LoginView();
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordView(),
      ),
      StatefulShellRoute.indexedStack(
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _rootNavigatorDashboard,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => DashboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorReports,
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => ViewIncidentsPage(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) => IncidentDetailsPage(
                      incident_id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => AddIncidentPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorSOS,
            routes: [
              GoRoute(
                path: '/sos',
                builder: (context, state) => ViewSosPage(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) => SosDetailsPage(id: state.pathParameters['id'] ?? ''),
                  ),
                  
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorUsers,
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => UsersView(),
                routes: [
                  GoRoute(
                    path: 'update/:uID',
                    builder: (context, state) => UpdateUserView(
                      userID: state.pathParameters['uID'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorNews,
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => NewsPage(),
                routes: [
                  GoRoute(
                    path: 'update/:id',
                    builder: (context, state) => UpdateNewsPage(
                        news_id: state.pathParameters['id'] ?? ''),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorComplaints,
            routes: [
              GoRoute(
                path: '/complaints',
                builder: (context, state) => ViewComplaintsPage(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) => ComplaintDetailsPage(
                      complaint_id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // StatefulShellBranch(
          //   navigatorKey: _rootNavigatorSchedule,
          //   routes: [
          //     GoRoute(
          //       path: '/schedule',
          //       builder: (context, state) => ScheduleMeetingPage(),
          //     ),
          //   ],
          // ),
        ],
        builder: (context, state, navigationShell) {
          return NavigationMenu(
            navigationShell: navigationShell,
          );
        },
      )
    ],
  );
}
