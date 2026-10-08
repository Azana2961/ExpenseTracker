import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../expenses/models/expense_model.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptWidget extends StatefulWidget {
  final ExpenseModel expense;

  const ReceiptWidget({super.key, required this.expense});

  @override
  State<ReceiptWidget> createState() => _ReceiptWidgetState();
}

class _ReceiptWidgetState extends State<ReceiptWidget> {
  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _shareReceipt() async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = (await getTemporaryDirectory()).path;
      final imgFile = File('$directory/receipt_${widget.expense.id}.png');
      await imgFile.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imgFile.path)],
        text: 'Receipt from Kharcha Yar',
      );
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoan = widget.expense.category == 'Loan';
    final Color primaryColor = isLoan ? Colors.green.shade600 : Colors.red.shade600;
    
    // Fallback if ID is just a timestamp or UUID, we make a short one for display
    final shortId = widget.expense.id.length > 8 
        ? widget.expense.id.substring(0, 8).toUpperCase() 
        : widget.expense.id.toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _receiptKey,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header (Icon + Title) ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: const DecorationImage(
                              image: AssetImage('assets/icon.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Kharcha Yar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLoan ? "It's a Loan" : "It's a Borrow",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // ── Dashed Divider ─────────────────────────────────────────
                Row(
                  children: List.generate(
                    30,
                    (index) => Expanded(
                      child: Container(
                        height: 1,
                        color: index.isEven ? Colors.grey.shade400 : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // ── Date & ID ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Date', DateFormat('dd MMM yyyy, hh:mm a').format(widget.expense.date)),
                    _buildInfoColumn('Receipt ID', '#$shortId', alignment: CrossAxisAlignment.end),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // ── Name & Description ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Name', widget.expense.beneficiary ?? 'Unknown'),
                    _buildInfoColumn('Description', widget.expense.label, alignment: CrossAxisAlignment.end),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ── Amount & Stamp ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${widget.expense.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      
                      // The "Unpaid" Stamp
                      if (!widget.expense.isCleared)
                        Positioned(
                          right: 0,
                          top: -4,
                          child: Transform.rotate(
                            angle: -math.pi / 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.shade700, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'UNPAID',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                         Positioned(
                          right: 0,
                          top: -4,
                          child: Transform.rotate(
                            angle: -math.pi / 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green.shade700, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PAID',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // ── Footer text ────────────────────────────────────────────
                Center(
                  child: Text(
                    "Sent so You don't forget",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _shareReceipt,
          icon: const Icon(Icons.share, size: 20),
          label: const Text(
            'Share Receipt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String title, String value, {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
