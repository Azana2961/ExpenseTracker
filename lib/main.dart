import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/expenses/presentation/expense_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/setup/presentation/setup_screen.dart';
import 'features/expenses/providers/expense_provider.dart'; 
import 'features/setup/providers/settings_provider.dart'; 
import 'core/theme/app_theme.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init(
    onDidReceiveNotificationResponse: (payload) {
      // Small delay to ensure GoRouter is fully initialized before navigating
      Future.delayed(const Duration(milliseconds: 100), () {
        _router.go('/dashboard');
      });
    }
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: const HostelExpenseApp(),
    ),
  );
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({super.key, required this.index, required this.children});

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(_controller),
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, required this.children, super.key});
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Map visible tab indices to shell branch indices.
    // Tab 0 = Dashboard (branch 0), Tab 1 = Add (standalone /expense route),
    // Tab 2 = Analytics (branch 1), Tab 3 = Setup (branch 2).
    int shellBranchFor(int tabIndex) {
      if (tabIndex <= 0) return 0;
      if (tabIndex == 2) return 1;
      return 2;
    }

    // The "selected" indicator for the nav bar. Expense tab (1) is never
    // "active" in the shell sense, so always highlight the last shell branch.
    final selectedIndex = navigationShell.currentIndex == 0
        ? 0
        : navigationShell.currentIndex == 1
            ? 2
            : navigationShell.currentIndex == 2
                ? 3
                : 0;

    return Scaffold(
      body: FadeIndexedStack(
        index: navigationShell.currentIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Expense is a standalone top-level route — push it so the shell
            // stays alive behind it and the back button returns to the shell.
            context.push('/expense', extra: DateTime.now());
          } else {
            navigationShell.goBranch(
              shellBranchFor(index),
              initialLocation: shellBranchFor(index) == navigationShell.currentIndex,
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF2EC4B6)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle, color: Color(0xFF2EC4B6)), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics, color: Color(0xFF2EC4B6)), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFF2EC4B6)), label: 'Setup'),
        ],
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // ── Top-level expense route (NOT inside StatefulShellRoute) ─────────────
    // This is intentionally a standalone route so the screen is rebuilt fresh
    // every time it is pushed, which guarantees `initialDate` from `extra` is
    // always picked up — even when navigating from a past day on the dashboard.
    GoRoute(
      path: '/expense',
      builder: (context, state) =>
          ExpenseScreen(initialDate: state.extra as DateTime?),
    ),
    StatefulShellRoute(
      builder: (context, state, navigationShell) => navigationShell,
      navigatorContainerBuilder: (context, navigationShell, children) {
        return ScaffoldWithNavBar(navigationShell: navigationShell, children: children);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/setup', builder: (context, state) => const SetupScreen())]),
      ],
    ),
  ],
);


class HostelExpenseApp extends StatefulWidget {
  const HostelExpenseApp({super.key});

  @override
  State<HostelExpenseApp> createState() => _HostelExpenseAppState();
}

class _HostelExpenseAppState extends State<HostelExpenseApp> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
    await notificationService.scheduleDailyNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kharcha Yar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}