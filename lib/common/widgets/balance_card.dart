import 'package:flutter/material.dart';
import '../../models/work_session.dart';
import '../../utils/time_formatter.dart';
import '../constants/app_colors.dart';

/// Card widget that displays the total work hours balance
class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double todayHours;
  final WorkSession? activeSession;
  final List<WorkSession> todaySessions;
  final AnimationController? pulseController;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.todayHours,
    required this.activeSession,
    required this.todaySessions,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate real-time balance with active session
    double realtimeBalance = totalBalance;
    if (activeSession != null) {
      // Calculate non-active sessions' hours for today
      final nonActiveHours = todaySessions
          .where((s) => s.id != activeSession!.id)
          .fold<double>(
            0.0,
            (sum, s) =>
                sum + (s.clockOut!.difference(s.clockIn).inMinutes / 60.0),
          );

      // Calculate real-time active session hours
      final activeSeconds = DateTime.now()
          .difference(activeSession!.clockIn)
          .inSeconds;
      final activeHours = activeSeconds / 3600.0;

      // Recalculate today's total with real-time active session
      final realtimeTodayHours = nonActiveHours + activeHours;

      // Adjust balance: remove old today's hours, add real-time today's hours
      realtimeBalance = totalBalance - todayHours + realtimeTodayHours;
    }

    final isPositive = realtimeBalance >= 0;
    final color = isPositive
        ? AppColors.getPositiveBalanceColor(context)
        : AppColors.getNegativeBalanceColor(context);
    final backgroundColor = isPositive
        ? AppColors.getPositiveBalanceBackgroundColor(context)
        : AppColors.getNegativeBalanceBackgroundColor(context);

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (activeSession != null && pulseController != null)
                  FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.3,
                      end: 1.0,
                    ).animate(pulseController!),
                    child: Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: color,
                      size: 32,
                    ),
                  )
                else
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: color,
                    size: 32,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Total Balance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show real-time balance with seconds precision when active
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isPositive ? '+' : ''}${TimeFormatter.formatHours(realtimeBalance)}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (activeSession != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 20, color: color),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPositive
                  ? activeSession != null
                        ? 'Balance growing! Keep it up! 🚀'
                        : 'You are ahead! Great job! 🎉'
                  : activeSession != null
                  ? 'Working to catch up! 💪'
                  : 'You need to catch up 💪',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
