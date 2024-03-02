import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:irs_admin/views/dashboard_view.dart';
import 'package:irs_admin/views/forgot_password_view.dart';
import 'package:irs_admin/views/login_view.dart';
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
  static final _rootNavigatorUsers =
      GlobalKey<NavigatorState>(debugLabel: "shellUsers");
  static final _rootNavigatorNews =
      GlobalKey<NavigatorState>(debugLabel: "shellNews");
  static final _rootNavigatorRequests =
      GlobalKey<NavigatorState>(debugLabel: "shellRequests");
  static final _rootNavigatorSchedule =
      GlobalKey<NavigatorState>(debugLabel: "shellSchedule");

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
                builder: (context, state) => Center(
                  child: Text("Reports"),
                ),
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
                builder: (context, state) => Center(
                  child: Text("News"),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorRequests,
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => Center(
                  child: Text("Requests"),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _rootNavigatorSchedule,
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => Center(
                  child: Text("Schedule"),
                ),
              ),
            ],
          ),
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
