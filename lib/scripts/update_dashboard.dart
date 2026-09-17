import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String content = file.readAsStringSync();

  // 1. Update _originDayContribution
  content = content.replaceAll(
      "if (tx.category == 'Borrow') return 0.0;   // received money",
      "if (tx.category == 'Loan') return 0.0;   // received money");

  // 2. Update _monthlyContribution
  content = content.replaceAll(
      "if (tx.category == 'Borrow') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Loan')   return tx.remainingAmount; // net owed",
      "if (tx.category == 'Loan') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Borrow')   return tx.remainingAmount; // net owed");

  // 3. Update currentSpent repayments
  content = content.replaceAll(
      "if (r.category == 'Loan' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }",
      "if (r.category == 'Borrow' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }");

  // 4. Update selectedDaySpent repayments
  content = content.replaceAll(
      "// b) Borrow repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Loan repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }",
      "// b) Loan repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Borrow repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }");

  // 5. Remove budget/stats section and re-apply wallet row
  final wallet_chunk = '''              // 1 ── Wallet Row (Teal card + Loans/Borrows) ──────────────
              _WalletRow(
                selectedDaySpent: selectedDaySpent,
                hasActiveLoan: hasActiveLoan,
                hasActiveBorrow: hasActiveBorrow,
                onLoanTap: () => _showLoanBorrowSheet(
                  context, 'Loan', allExpenses, provider, settings),
                onBorrowTap: () => _showLoanBorrowSheet(
                  context, 'Borrow', allExpenses, provider, settings),
              ),
              const SizedBox(height: 16),

              // 2 ── Monthly Budget bar ─────────────────────────────────
              _buildMonthlyBudgetSection(
                currentSpent: currentSpent,
                monthlyBudget: monthlyBudget,
                budgetPercentage: budgetPercentage,
              ),
              const SizedBox(height: 14),

              // 3 ── Stats row ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      'Avg Spent',
                      'Rs \${dailyAverageSpent.toStringAsFixed(0)}',
                      _primaryTeal.withValues(alpha: 0.1),
                      _primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBox(
                      'Ideal Daily',
                      'Rs \${idealDailySpend.toStringAsFixed(0)}',
                      Colors.purple.withValues(alpha: 0.1),
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBox(
                      'Safe to Spend',
                      'Rs \${safeDailySpend.toStringAsFixed(0)}',
                      Colors.orange.withValues(alpha: 0.1),
                      Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),''';
  final new_wallet = '''              // 1 ── Wallet Row (Teal card + Loans/Borrows) ──────────────
              _WalletRow(
                selectedDaySpent: selectedDaySpent,
                budgetPercentage: budgetPercentage,
                hasActiveLoan: hasActiveLoan,
                hasActiveBorrow: hasActiveBorrow,
                onLoanTap: () => _showLoanBorrowSheet(
                  context, 'Loan', allExpenses, provider, settings),
                onBorrowTap: () => _showLoanBorrowSheet(
                  context, 'Borrow', allExpenses, provider, settings),
              ),
              const SizedBox(height: 20),''';
  content = content.replaceAll(wallet_chunk, new_wallet);

  // 6. Delete _buildMonthlyBudgetSection and _buildInfoBox using regex
  final regex = RegExp(r'  // ─── Monthly Budget Section.*?  // ─── Loan / Borrow bottom sheet', dotAll: true);
  content = content.replaceAll(regex, '  // ─── Loan / Borrow bottom sheet');

  // 7. Update _showRecordPaymentSheet
  content = content.replaceAll(
      "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;",
      "final accentColor =\n        isLoan ? Colors.red.shade700 : Colors.green.shade700;");

  // 8. Update _showLoanBorrowSheet
  content = content.replaceAll(
      "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;\n    final bgColor = isLoan ? Colors.green.shade50 : Colors.red.shade50;\n    final borderColor =\n        isLoan ? Colors.green.shade200 : Colors.red.shade200;",
      "final accentColor =\n        isLoan ? Colors.red.shade700 : Colors.green.shade700;\n    final bgColor = isLoan ? Colors.red.shade50 : Colors.green.shade50;\n    final borderColor =\n        isLoan ? Colors.red.shade200 : Colors.green.shade200;");
  content = content.replaceAll(
      "isLoan\n                                  ? 'Money others owe you'\n                                  : 'Money you owe others',",
      "isLoan\n                                  ? 'Money you owe others'\n                                  : 'Money others owe you',");

  // 9. _WalletRow class replace
  final wallet_class_regex = RegExp(r'class _WalletRow extends StatelessWidget \{.*?\n\}\n', dotAll: true);
  final new_wallet_row_class = '''class _WalletRow extends StatelessWidget {
  final double selectedDaySpent;
  final double budgetPercentage;
  final bool hasActiveLoan;
  final bool hasActiveBorrow;
  final VoidCallback onLoanTap;
  final VoidCallback onBorrowTap;

  const _WalletRow({
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
                sublabel: 'I owe',
                icon: Icons.account_balance_wallet_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8E8E), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFFFF6B6B),
                hasNotification: hasActiveLoan,
                onTap: onLoanTap,
              ),
            ),
            const SizedBox(width: 12),
            // Borrows button
            Expanded(
              child: _ActionButton(
                label: 'Borrows',
                sublabel: 'Owed to me',
                icon: Icons.handshake_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5BA3E8), Color(0xFF4A90D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF4A90D9),
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
  content = content.replaceAll(wallet_class_regex, new_wallet_row_class);

  // 10. Update _DailyLedger
  content = content.replaceAll(
      "isToday: isToday,",
      "isCreationDay: tx.date.year == selectedDate.year &&\n                         tx.date.month == selectedDate.month &&\n                         tx.date.day == selectedDate.day,");

  // 11. Update _RepaymentCard
  content = content.replaceAll(
      "    // Borrow repayment → you PAID OUT (red, debit)\n    // Loan repayment   → you RECEIVED (green, credit)\n    final color  = isBorrow ? Colors.red.shade700 : Colors.green.shade700;\n    final bg     = isBorrow ? Colors.red.shade50   : Colors.green.shade50;\n    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;\n    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';\n    final prefix = isBorrow ? '- Rs ' : '+ Rs ';\n",
      "    // Loan repayment → you PAID OUT (red, debit)\n    // Borrow repayment → you RECEIVED (green, credit)\n    final color  = isBorrow ? Colors.green.shade700 : Colors.red.shade700;\n    final bg     = isBorrow ? Colors.green.shade50   : Colors.red.shade50;\n    final icon   = isBorrow ? Icons.arrow_downward   : Icons.arrow_upward;\n    final label  = isBorrow ? 'Received back (Borrow)' : 'Paid back (Loan)';\n    final prefix = isBorrow ? '+ Rs ' : '- Rs ';\n");

  // 12. Update _TransactionCard signature and usages
  content = content.replaceAll("final bool isToday;", "final bool isCreationDay;");
  content = content.replaceAll("this.isToday = true,", "this.isCreationDay = true,");
  content = content.replaceAll("onLongPress: isToday ? onEdit : null,", "onLongPress: isCreationDay ? onEdit : null,");
  content = content.replaceAll("if (isToday)\n                  InkWell(", "if (isCreationDay)\n                  InkWell(");
  content = content.replaceAll("onTap: isSpecial && !isCleared && isToday ? onRecordPayment : null,", "onTap: isSpecial && !isCleared ? onRecordPayment : null,");

  // 13. Update _TransactionCard color logic
  content = content.replaceAll(
      "        amountColor   = isLoan ? Colors.green : Colors.redAccent;\n        amountPrefix  = isLoan ? '+ ' : '- ';\n      } else {\n        amountPrefix  = '⏳ ';\n        if (isLoan) {",
      "        amountColor   = isBorrow ? Colors.green : Colors.redAccent;\n        amountPrefix  = isBorrow ? '+ ' : '- ';\n      } else {\n        amountPrefix  = '⏳ ';\n        if (isBorrow) {");

  file.writeAsStringSync(content);
}
