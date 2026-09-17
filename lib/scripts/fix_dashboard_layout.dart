import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String content = file.readAsStringSync();

  // 1. Delete _buildMonthlyBudgetSection and _buildInfoBox calls and the stats row
  final regexCallBlock = RegExp(r'              // 2 ── Monthly Budget bar ─────────────────────────────────.*?              // 4 ── Date Navigation ────────────────────────────────────', dotAll: true);
  content = content.replaceAll(regexCallBlock, '              // 4 ── Date Navigation ────────────────────────────────────');

  // 2. Delete _buildMonthlyBudgetSection function definition
  final regexFuncBlock = RegExp(r'  // ─── Monthly Budget Section ────────────────────────────────────────────────.*?  // ─── Loan / Borrow bottom sheet ────────────────────────────────────────────', dotAll: true);
  content = content.replaceAll(regexFuncBlock, '  // ─── Loan / Borrow bottom sheet ────────────────────────────────────────────');

  // 3. Update _WalletRow call to pass budgetPercentage
  content = content.replaceAll(
      "                hasActiveBorrow: hasActiveBorrow,",
      "                budgetPercentage: budgetPercentage,\n                hasActiveBorrow: hasActiveBorrow,");

  // 4. Replace _WalletRow class completely
  final oldWalletRowRegex = RegExp(r'// ═══════════════════════════════════════════════════════════════════════════════\n//  WALLET ROW  \(private widget\)\n// ═══════════════════════════════════════════════════════════════════════════════\nclass _WalletRow extends StatelessWidget \{.*?\n\}\n', dotAll: true);
  
  final newWalletRow = '''// ═══════════════════════════════════════════════════════════════════════════════
//  WALLET ROW  (private widget)
// ═══════════════════════════════════════════════════════════════════════════════
class _WalletRow extends StatelessWidget {
  final double selectedDaySpent;
  final double budgetPercentage;
  final bool hasActiveLoan;
  final bool hasActiveBorrow;
  final VoidCallback onLoanTap;
  final VoidCallback onBorrowTap;

  const _WalletRow({
    super.key,
    required this.selectedDaySpent,
    required this.budgetPercentage,
    required this.hasActiveLoan,
    required this.hasActiveBorrow,
    required this.onLoanTap,
    required this.onBorrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Main Teal "Today Spent" card ──────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2EC4B6), Color(0xFF22A89D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.today_outlined,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Spent',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Rs \${selectedDaySpent.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: budgetPercentage,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budgetPercentage > 0.9 ? Colors.redAccent : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Action buttons row ─────────────────────────────────────
        Row(
          children: [
            // Loans button
            Expanded(
              child: _ActionButton(
                label: 'Loans',
                sublabel: 'Owed to me',
                icon: Icons.handshake_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5BA3E8), Color(0xFF4A90D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF4A90D9),
                hasNotification: hasActiveLoan,
                onTap: onLoanTap,
              ),
            ),
            const SizedBox(width: 12),
            // Borrows button
            Expanded(
              child: _ActionButton(
                label: 'Borrows',
                sublabel: 'I owe',
                icon: Icons.account_balance_wallet_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8E8E), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFFFF6B6B),
                hasNotification: hasActiveBorrow,
                onTap: onBorrowTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
''';

  content = content.replaceAll(oldWalletRowRegex, newWalletRow);

  // 5. Change isToday to isCreationDay for _TransactionCard
  content = content.replaceAll("this.isToday = true,", "this.isCreationDay = true,");
  content = content.replaceAll("final bool isToday;", "final bool isCreationDay;");
  content = content.replaceAll("onLongPress: isToday ? onEdit : null,", "onLongPress: isCreationDay ? onEdit : null,");
  content = content.replaceAll("if (isToday)\\n                  InkWell(", "if (isCreationDay)\\n                  InkWell(");
  // Using exact string matching for the edit icon if check
  content = content.replaceAll("if (isToday)\n                  InkWell(", "if (isCreationDay)\n                  InkWell(");

  // Fix the onTap logic for onRecordPayment
  content = content.replaceAll("onTap: isSpecial && !isCleared && isToday ? onRecordPayment : null,", "onTap: isSpecial && !isCleared ? onRecordPayment : null,");
  
  // Fix the boolean passed into _TransactionCard in _DailyLedger
  content = content.replaceAll(
      "isToday: isToday,",
      "isCreationDay: tx.date.year == selectedDate.year && tx.date.month == selectedDate.month && tx.date.day == selectedDate.day,");


  file.writeAsStringSync(content);
}
