import 'dart:io';

void main() {
  final file = File('frontend/lib/features/dashboard/presentation/dashboard_screen.dart');
  String c = file.readAsStringSync();

  // 1. Restyle _RepaymentCard
  final oldRepaymentCard = '''class _RepaymentCard extends StatelessWidget {
  final RepaymentModel repayment;
  const _RepaymentCard({required this.repayment});

  @override
  Widget build(BuildContext context) {
    final isBorrow = repayment.category == 'Borrow';
    // Borrow repayment → you PAID OUT (red, debit)
    // Loan repayment   → you RECEIVED (green, credit)
    final color  = isBorrow ? Colors.red.shade700 : Colors.green.shade700;
    final bg     = isBorrow ? Colors.red.shade50   : Colors.green.shade50;
    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;
    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';
    final prefix = isBorrow ? '- Rs ' : '+ Rs ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(repayment.date),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '\$prefix\${repayment.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}''';

  final newRepaymentCard = '''class _RepaymentCard extends StatelessWidget {
  final RepaymentModel repayment;
  const _RepaymentCard({required this.repayment});

  @override
  Widget build(BuildContext context) {
    final isBorrow = repayment.category == 'Borrow';
    // Borrow repayment → you PAID OUT (red, debit)
    // Loan repayment   → you RECEIVED (green, credit)
    final color  = isBorrow ? Colors.red.shade600 : Colors.green.shade600;
    final bg     = isBorrow ? const Color(0xFFFFECEC) : const Color(0xFFECF9EC);
    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;
    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';
    final prefix = isBorrow ? '- Rs ' : '+ Rs ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(repayment.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              '\$prefix\${repayment.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}''';

  c = c.replaceAll(oldRepaymentCard, newRepaymentCard);

  // 2. Add compact non-creation-day view to _TransactionCard
  // Find the build method body start and inject the new path before the existing logic
  final oldBuildStart = '''  @override
  Widget build(BuildContext context) {
    final isLoan   = tx.category == 'Loan';
    final isBorrow = tx.category == 'Borrow';
    final isSpecial = isLoan || isBorrow;
    final isCleared = tx.isCleared;

    Color amountColor  = Colors.redAccent;
    String amountPrefix = '- ';
    Color containerColor = Colors.white;
    Color borderColor  = Colors.grey.shade100;
    Color iconBgColor  = primaryTeal.withValues(alpha: 0.1);
    Color iconColor    = primaryTeal;

    if (isSpecial) {
      if (isCleared) {
        amountColor   = isLoan ? Colors.green : Colors.redAccent;
        amountPrefix  = isLoan ? '+ ' : '- ';
      } else {
        amountPrefix  = '⏳ ';
        if (isLoan) {
          amountColor   = Colors.green.shade700;
          containerColor = Colors.green.shade50;
          borderColor   = Colors.green.shade200;
          iconBgColor   = Colors.green.withValues(alpha: 0.2);
          iconColor     = Colors.green.shade700;
        } else {
          amountColor   = Colors.red.shade700;
          containerColor = Colors.red.shade50;
          borderColor   = Colors.red.shade200;
          iconBgColor   = Colors.red.withValues(alpha: 0.2);
          iconColor     = Colors.red.shade700;
        }
      }
    }''';

  final newBuildStart = '''  @override
  Widget build(BuildContext context) {
    final isLoan    = tx.category == 'Loan';
    final isBorrow  = tx.category == 'Borrow';
    final isSpecial = isLoan || isBorrow;
    final isCleared = tx.isCleared;

    final Color accentColor = isLoan
        ? Colors.green.shade600
        : isBorrow
            ? Colors.red.shade600
            : primaryTeal;
    final Color bgColor = isSpecial && !isCleared
        ? (isLoan ? const Color(0xFFECF9EC) : const Color(0xFFFFECEC))
        : Colors.white;

    // Non-creation-day: compact tappable tracking card
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
                            ? '\${tx.category} • Rs \${tx.amountPaid.toStringAsFixed(0)} paid'
                            : '\${tx.category} • Tap to pay',
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
                      '⏳ Rs \${tx.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 15),
                    ),
                    if (tx.isPartiallyPaid)
                      Text(
                        'Paid: \${tx.amountPaid.toStringAsFixed(0)} / \${tx.amount.toStringAsFixed(0)}',
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

    Color amountColor  = Colors.redAccent;
    String amountPrefix = '- ';
    Color containerColor = bgColor;
    Color borderColor  = isSpecial && !isCleared
        ? accentColor.withValues(alpha: 0.2)
        : Colors.grey.shade100;
    Color iconBgColor  = accentColor.withValues(alpha: 0.15);
    Color iconColor    = accentColor;

    if (isSpecial) {
      if (isCleared) {
        amountColor  = isLoan ? Colors.green : Colors.redAccent;
        amountPrefix = isLoan ? '+ ' : '- ';
      } else {
        amountPrefix = '⏳ ';
        amountColor  = accentColor;
      }
    }''';

  c = c.replaceAll(oldBuildStart, newBuildStart);

  // 3. Update the icon/leading in the creation-day card to use the unified accentColor
  c = c.replaceAll(
    '            leading: CircleAvatar(\n              backgroundColor:\n                  !isCleared ? iconBgColor : primaryTeal.withValues(alpha: 0.1),\n              child: Icon(getCategoryIcon(tx.category),\n                  color: !isCleared ? iconColor : primaryTeal),\n            ),',
    '            leading: CircleAvatar(\n              backgroundColor:\n                  !isCleared ? iconBgColor : primaryTeal.withValues(alpha: 0.1),\n              child: Icon(getCategoryIcon(tx.category),\n                  color: !isCleared ? iconColor : primaryTeal),\n            ),'
  );

  file.writeAsStringSync(c);
  print('Done!');
}
