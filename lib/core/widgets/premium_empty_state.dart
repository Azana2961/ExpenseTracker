import 'package:flutter/material.dart';

class PremiumEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PremiumEmptyState({
    super.key, 
    this.title = 'No Data Yet', 
    this.subtitle = 'Your insights will appear here once you start adding data.',
    this.icon = Icons.analytics_outlined,
  });

  @override
  State<PremiumEmptyState> createState() => _PremiumEmptyStateState();
}

class _PremiumEmptyStateState extends State<PremiumEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Continuous floating animation
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -10 * _floatController.value), // Floats up and down
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 60, color: const Color(0xFF2EC4B6)),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}