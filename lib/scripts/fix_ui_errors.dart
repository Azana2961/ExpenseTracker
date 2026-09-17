import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String content = file.readAsStringSync();

  // 1. Delete _buildMonthlyBudgetSection and _buildInfoBox from the UI tree
  final regex = RegExp(r'              // 2 ── Monthly Budget bar ─────────────────────────────────.*?              // 4 ── Date Navigation ────────────────────────────────────', dotAll: true);
  content = content.replaceAll(regex, '              // 4 ── Date Navigation ────────────────────────────────────');

  // 2. Change isToday to isCreationDay
  content = content.replaceAll('if (isToday)', 'if (isCreationDay)');

  file.writeAsStringSync(content);
}
