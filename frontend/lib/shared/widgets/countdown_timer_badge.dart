import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CountdownTimerBadge extends StatefulWidget {
  final bool isCompact;

  const CountdownTimerBadge({
    super.key,
    this.isCompact = false,
  });

  @override
  State<CountdownTimerBadge> createState() => _CountdownTimerBadgeState();
}

class _CountdownTimerBadgeState extends State<CountdownTimerBadge> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateRemaining());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    // Midnight cutoff is next day 00:00:00
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    if (widget.isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.saffronSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.saffron.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 14, color: AppColors.saffron),
            const SizedBox(width: 5),
            Text(
              '$hours:$minutes:$seconds left',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.saffron,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.saffronSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saffron.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_rounded, color: AppColors.saffron, size: 18),
              const SizedBox(width: 8),
              Text(
                'Book before 12:00 AM IST',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.saffron,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(hours, 'Hours'),
              _buildColon(),
              _buildTimeBox(minutes, 'Minutes'),
              _buildColon(),
              _buildTimeBox(seconds, 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.accentWarm,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.accentWarm.withOpacity(0.8),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
