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
  
  /// The duration of the active session when the state was last loaded.
  final int? activeSessionDurationSecondsAtLoad;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.todayHours,
    required this.activeSession,
    required this.todaySessions,
    required this.activeSessionDurationSecondsAtLoad,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate real-time balance with active session
    double realtimeBalance = totalBalance;
    
    if (activeSession != null && activeSessionDurationSecondsAtLoad != null) {
      // Calculate the current duration of the active session
      final currentActiveSeconds = activeSession!.durationSeconds;
      
      // Calculate the time passed (delta) since the last state load
      final deltaSeconds = currentActiveSeconds - activeSessionDurationSecondsAtLoad!;
      
      // Add the delta to the balance. 
      // This works correctly even if the session spans past midnight 
      // because we only add the time elapsed since the last calculation.
      realtimeBalance = totalBalance + (deltaSeconds / 3600.0);
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
