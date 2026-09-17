import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String content = file.readAsStringSync();

  // 1. Update _originDayContribution
  content = content.replaceAll(
      "if (tx.category == 'Loan') return 0.0;   // received money",
      "if (tx.category == 'Borrow') return 0.0;   // received money");

  // 2. Update _monthlyContribution
  content = content.replaceAll(
      "if (tx.category == 'Loan') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Borrow')   return tx.remainingAmount; // net owed",
      "if (tx.category == 'Borrow') return tx.amountPaid;     // net cash out\n    if (tx.category == 'Loan')   return tx.remainingAmount; // net owed");

  // 3. Update currentSpent repayments
  content = content.replaceAll(
      "if (r.category == 'Borrow' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }",
      "if (r.category == 'Loan' &&\n          r.date.month == today.month &&\n          r.date.year  == today.year) {\n        currentSpent -= r.amount;\n      }");

  // 4. Update selectedDaySpent repayments
  content = content.replaceAll(
      "// b) Loan repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Borrow repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }",
      "// b) Borrow repayments made on this day (cash left your pocket)\n    for (final r in allRepayments) {\n      if (r.category == 'Borrow' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent += r.amount;\n      }\n    }\n    // c) Loan repayments received on this day (cash came back → reduce spent)\n    for (final r in allRepayments) {\n      if (r.category == 'Loan' &&\n          _isSameDay(_dateOnly(r.date), _selectedDate)) {\n        selectedDaySpent -= r.amount;\n      }\n    }");

  // 7. Update _showRecordPaymentSheet
  content = content.replaceAll(
      "final accentColor =\n        isLoan ? Colors.red.shade700 : Colors.green.shade700;",
      "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;");

  // 8. Update _showLoanBorrowSheet
  content = content.replaceAll(
      "final accentColor =\n        isLoan ? Colors.red.shade700 : Colors.green.shade700;\n    final bgColor = isLoan ? Colors.red.shade50 : Colors.green.shade50;\n    final borderColor =\n        isLoan ? Colors.red.shade200 : Colors.green.shade200;",
      "final accentColor =\n        isLoan ? Colors.green.shade700 : Colors.red.shade700;\n    final bgColor = isLoan ? Colors.green.shade50 : Colors.red.shade50;\n    final borderColor =\n        isLoan ? Colors.green.shade200 : Colors.red.shade200;");
  content = content.replaceAll(
      "isLoan\n                                  ? 'Money you owe others'\n                                  : 'Money others owe you',",
      "isLoan\n                                  ? 'Money others owe you'\n                                  : 'Money you owe others',");

  // 11. Update _RepaymentCard
  content = content.replaceAll(
      "    // Loan repayment → you PAID OUT (red, debit)\n    // Borrow repayment → you RECEIVED (green, credit)\n    final color  = isBorrow ? Colors.green.shade700 : Colors.red.shade700;\n    final bg     = isBorrow ? Colors.green.shade50   : Colors.red.shade50;\n    final icon   = isBorrow ? Icons.arrow_downward   : Icons.arrow_upward;\n    final label  = isBorrow ? 'Received back (Borrow)' : 'Paid back (Loan)';\n    final prefix = isBorrow ? '+ Rs ' : '- Rs ';\n",
      "    // Borrow repayment → you PAID OUT (red, debit)\n    // Loan repayment   → you RECEIVED (green, credit)\n    final color  = isBorrow ? Colors.red.shade700 : Colors.green.shade700;\n    final bg     = isBorrow ? Colors.red.shade50   : Colors.green.shade50;\n    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;\n    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';\n    final prefix = isBorrow ? '- Rs ' : '+ Rs ';\n");

  // 13. Update _TransactionCard color logic
  content = content.replaceAll(
      "        amountColor   = isBorrow ? Colors.green : Colors.redAccent;\n        amountPrefix  = isBorrow ? '+ ' : '- ';\n      } else {\n        amountPrefix  = '⏳ ';\n        if (isBorrow) {",
      "        amountColor   = isLoan ? Colors.green : Colors.redAccent;\n        amountPrefix  = isLoan ? '+ ' : '- ';\n      } else {\n        amountPrefix  = '⏳ ';\n        if (isLoan) {");

  content = content.replaceAll(
      '''
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
''',
      '''
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
''');

  content = content.replaceAll(
      '''
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
''',
      '''
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
''');

  file.writeAsStringSync(content);
}
