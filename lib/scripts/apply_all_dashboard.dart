import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String c = file.readAsStringSync();

  // ── 1. Loan/Borrow semantics (from update_dashboard script) ──────────────

  // _originDayContribution: Loan = free money received, don't count
  c = c.replaceAll(
    "if (tx.category == 'Borrow') return 0.0;   // received money",
    "if (tx.category == 'Loan') return 0.0;   // received money");

  // _monthlyContribution
  c = c.replaceAll(
    "if (tx.category == 'Borrow') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Loan')   return tx.remainingAmount; // net owed",
    "if (tx.category == 'Loan') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Borrow')   return tx.remainingAmount; // net owed");

  // currentSpent repayments
  c = c.replaceAll(
    "if (r.category == 'Loan' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }",
    "if (r.category == 'Borrow' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }");

  // selectedDaySpent repayments
  c = c.replaceAll(
    "// b) Borrow repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Loan repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }",
    "// b) Loan repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Borrow repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }");

  // ── 2. hasActiveLoan: Loan = we gave (owed to us), Borrow = we received (we owe) ──
  // Already correct in original, just keep hasActiveLoan as 'Loan' check
  // and hasActiveBorrow as 'Borrow' check - no change needed

  // ── 3. Add budgetPercentage to _WalletRow ───────────────────────────────
  c = c.replaceAll(
    "  final double selectedDaySpent;\n  final bool hasActiveLoan;\n  final bool hasActiveBorrow;\n  final VoidCallback onLoanTap;\n  final VoidCallback onBorrowTap;\n\n  const _WalletRow({\n    required this.selectedDaySpent,\n    required this.hasActiveLoan,\n    required this.hasActiveBorrow,\n    required this.onLoanTap,\n    required this.onBorrowTap,\n  });",
    "  final double selectedDaySpent;\n  final double budgetPercentage;\n  final bool hasActiveLoan;\n  final bool hasActiveBorrow;\n  final VoidCallback onLoanTap;\n  final VoidCallback onBorrowTap;\n\n  const _WalletRow({\n    required this.selectedDaySpent,\n    required this.budgetPercentage,\n    required this.hasActiveLoan,\n    required this.hasActiveBorrow,\n    required this.onLoanTap,\n    required this.onBorrowTap,\n  });");

  // ── 4. Add budget bar to the teal card (after the amount Text) ────────────
  c = c.replaceAll(
    "                  const SizedBox(height: 8),\n                ],\n              ),\n            ),\n          ),\n          const SizedBox(width: 10),",
    "                  const SizedBox(height: 16),\n                  ClipRRect(\n                    borderRadius: BorderRadius.circular(10),\n                    child: LinearProgressIndicator(\n                      value: budgetPercentage.clamp(0.0, 1.0),\n                      minHeight: 6,\n                      backgroundColor: Colors.black.withValues(alpha: 0.1),\n                      valueColor: AlwaysStoppedAnimation<Color>(\n                        budgetPercentage > 0.9\n                            ? Colors.redAccent\n                            : Colors.white.withValues(alpha: 0.9),\n                      ),\n                    ),\n                  ),\n                ],\n              ),\n            ),\n          ),\n          const SizedBox(width: 10),");

  // ── 5. Pass budgetPercentage to _WalletRow call ──────────────────────────
  c = c.replaceAll(
    "                hasActiveLoan: hasActiveLoan,\n                hasActiveBorrow: hasActiveBorrow,",
    "                budgetPercentage: budgetPercentage,\n                hasActiveLoan: hasActiveLoan,\n                hasActiveBorrow: hasActiveBorrow,");

  // ── 6. Remove stats/budget section from dashboard build (keep only wallet row) ──
  final regexCallBlock = RegExp(
    r'              // 2 ── Monthly Budget bar ─────────────────────────────────.*?              // 4 ── Date Navigation ────────────────────────────────────',
    dotAll: true);
  c = c.replaceAll(regexCallBlock,
    '              // 4 ── Date Navigation ────────────────────────────────────');

  // Remove _buildMonthlyBudgetSection and _buildInfoBox method defs
  final regexFuncBlock = RegExp(
    r'  // ─── Monthly Budget Section ────────────────────────────────────────────────.*?  // ─── Loan / Borrow bottom sheet ────────────────────────────────────────────',
    dotAll: true);
  c = c.replaceAll(regexFuncBlock,
    '  // ─── Loan / Borrow bottom sheet ────────────────────────────────────────────');

  // ── 7. _showRecordPaymentSheet colors ────────────────────────────────────
  c = c.replaceAll(
    "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;",
    "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;"); // unchanged

  // ── 8. _showLoanBorrowSheet: swap sublabel ────────────────────────────────
  c = c.replaceAll(
    "isLoan\n                                  ? 'Money others owe you'\n                                  : 'Money you owe others',",
    "isLoan\n                                  ? 'Money others owe you'\n                                  : 'Money you owe others',"); // unchanged, correct

  // ── 9. _DailyLedger: repayments shown on non-today days only ─────────────
  // Already correct in original

  // ── 10. _TransactionCard: isCreationDay instead of isToday ───────────────
  c = c.replaceAll("this.isToday = true,", "this.isCreationDay = true,");
  c = c.replaceAll("final bool isToday;", "final bool isCreationDay;");
  c = c.replaceAll("onLongPress: isToday ? onEdit : null,", "onLongPress: isCreationDay ? onEdit : null,");
  c = c.replaceAll("if (isToday)\n                  InkWell(", "if (isCreationDay)\n                  InkWell(");
  c = c.replaceAll("onTap: isSpecial && !isCleared && isToday ? onRecordPayment : null,", "onTap: isSpecial && !isCleared ? onRecordPayment : null,");
  c = c.replaceAll("isToday: isToday,",
    "isCreationDay: tx.date.year == selectedDate.year && tx.date.month == selectedDate.month && tx.date.day == selectedDate.day,");

  // ── 11. _RepaymentCard: polished style ───────────────────────────────────
  c = c.replaceAll(
    "    final color  = isBorrow ? Colors.red.shade700 : Colors.green.shade700;\n    final bg     = isBorrow ? Colors.red.shade50   : Colors.green.shade50;\n    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;\n    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';\n    final prefix = isBorrow ? '- Rs ' : '+ Rs ';\n\n    return Container(\n      margin: const EdgeInsets.only(bottom: 10),\n      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),\n      decoration: BoxDecoration(\n        color: bg,\n        borderRadius: BorderRadius.circular(14),\n        border: Border.all(color: color.withValues(alpha: 0.25)),\n      ),\n      child: Row(\n        children: [\n          CircleAvatar(\n            radius: 20,\n            backgroundColor: color.withValues(alpha: 0.15),\n            child: Icon(icon, color: color, size: 18),\n          ),\n          const SizedBox(width: 12),\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Text(\n                  label,\n                  style: TextStyle(\n                    fontWeight: FontWeight.bold,\n                    color: color,\n                    fontSize: 13,\n                  ),\n                ),\n                Text(\n                  DateFormat('MMM d, h:mm a').format(repayment.date),\n                  style: TextStyle(\n                      fontSize: 11, color: Colors.grey.shade500),\n                ),\n              ],\n            ),\n          ),\n          Text(\n            '\$prefix\${repayment.amount.toStringAsFixed(0)}',\n            style: TextStyle(\n              fontWeight: FontWeight.bold,\n              fontSize: 15,\n              color: color,\n            ),\n          ),\n        ],\n      ),\n    );",
    "    final color  = isBorrow ? Colors.red.shade600 : Colors.green.shade600;\n    final bg     = isBorrow ? const Color(0xFFFFECEC) : const Color(0xFFECF9EC);\n    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;\n    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';\n    final prefix = isBorrow ? '- Rs ' : '+ Rs ';\n\n    return Container(\n      margin: const EdgeInsets.only(bottom: 10),\n      decoration: BoxDecoration(\n        color: bg,\n        borderRadius: BorderRadius.circular(16),\n        boxShadow: [\n          BoxShadow(\n            color: Colors.black.withValues(alpha: 0.04),\n            blurRadius: 8,\n            offset: const Offset(0, 3),\n          ),\n        ],\n      ),\n      child: Padding(\n        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),\n        child: Row(\n          children: [\n            CircleAvatar(\n              radius: 22,\n              backgroundColor: color.withValues(alpha: 0.15),\n              child: Icon(icon, color: color, size: 18),\n            ),\n            const SizedBox(width: 14),\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  Text(\n                    label,\n                    style: const TextStyle(\n                      fontWeight: FontWeight.w700,\n                      color: Colors.black87,\n                      fontSize: 14,\n                    ),\n                  ),\n                  const SizedBox(height: 2),\n                  Text(\n                    DateFormat('MMM d, h:mm a').format(repayment.date),\n                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),\n                  ),\n                ],\n              ),\n            ),\n            Text(\n              '\$prefix\${repayment.amount.toStringAsFixed(0)}',\n              style: TextStyle(\n                fontWeight: FontWeight.bold,\n                fontSize: 15,\n                color: color,\n              ),\n            ),\n          ],\n        ),\n      ),\n    );");

  // ── 12. _TransactionCard: add compact non-creation-day view ──────────────
  final oldColorBlock = "    Color amountColor  = Colors.redAccent;\n    String amountPrefix = '- ';\n    Color containerColor = Colors.white;\n    Color borderColor  = Colors.grey.shade100;\n    Color iconBgColor  = primaryTeal.withValues(alpha: 0.1);\n    Color iconColor    = primaryTeal;\n\n    if (isSpecial) {\n      if (isCleared) {\n        amountColor   = isLoan ? Colors.green : Colors.redAccent;\n        amountPrefix  = isLoan ? '+ ' : '- ';\n      } else {\n        amountPrefix  = '⏳ ';\n        if (isLoan) {\n          amountColor   = Colors.green.shade700;\n          containerColor = Colors.green.shade50;\n          borderColor   = Colors.green.shade200;\n          iconBgColor   = Colors.green.withValues(alpha: 0.2);\n          iconColor     = Colors.green.shade700;\n        } else {\n          amountColor   = Colors.red.shade700;\n          containerColor = Colors.red.shade50;\n          borderColor   = Colors.red.shade200;\n          iconBgColor   = Colors.red.withValues(alpha: 0.2);\n          iconColor     = Colors.red.shade700;\n        }\n      }\n    }";

  final newColorBlock = r"""    final Color accentColor = isLoan
        ? Colors.green.shade600
        : isBorrow
            ? Colors.red.shade600
            : primaryTeal;
    final Color bgColor = isSpecial && !isCleared
        ? (isLoan ? const Color(0xFFECF9EC) : const Color(0xFFFFECEC))
        : Colors.white;

    // Non-creation-day: compact tappable tracking card (no edit)
    if (isSpecial && !isCreationDay && !isCleared) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRecordPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Icon(getCategoryIcon(tx.category),
                      color: accentColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        tx.isPartiallyPaid
                            ? '${tx.category} • Rs ${tx.amountPaid.toStringAsFixed(0)} paid'
                            : '${tx.category} • Tap to pay',
                        style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '⏳ Rs ${tx.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 15),
                    ),
                    if (tx.isPartiallyPaid)
                      Text(
                        'Paid: ${tx.amountPaid.toStringAsFixed(0)} / ${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: accentColor.withValues(alpha: 0.75)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Color amountColor   = Colors.redAccent;
    String amountPrefix = '- ';
    final Color containerColor = bgColor;
    final Color borderColor    = isSpecial && !isCleared
        ? accentColor.withValues(alpha: 0.2) : Colors.grey.shade100;
    final Color iconBgColor    = isCleared
        ? primaryTeal.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.15);
    final Color iconColor      = isCleared ? primaryTeal : accentColor;

    if (isSpecial) {
      if (isCleared) {
        amountColor  = isLoan ? Colors.green : Colors.redAccent;
        amountPrefix = isLoan ? '+ ' : '- ';
      } else {
        amountPrefix = '⏳ ';
        amountColor  = accentColor;
      }
    }""";

  c = c.replaceAll(oldColorBlock, newColorBlock);

  // Fix iconColor reference in ListTile subtitle (was using iconColor for text)
  c = c.replaceAll(
    "                color: isSpecial && !isCleared\n                    ? iconColor\n                    : Colors.grey.shade600,",
    "                color: isSpecial && !isCleared\n                    ? accentColor\n                    : Colors.grey.shade600,");

  file.writeAsStringSync(c);
  print('All done!');
}
