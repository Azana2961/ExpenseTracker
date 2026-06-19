import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/expenses/presentation/expense_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/setup/presentation/setup_screen.dart'; 

void main() {
  runApp(const HostelExpenseApp());
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
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
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/expense', builder: (context, state) => ExpenseScreen(selectedDate: state.extra as DateTime?))]),
        StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/setup', builder: (context, state) => const SetupScreen())]),
      ],
    ),
  ],
);

class HostelExpenseApp extends StatelessWidget {
  const HostelExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hostel Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2EC4B6)),
        scaffoldBackgroundColor: Colors.grey.shade50,
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}