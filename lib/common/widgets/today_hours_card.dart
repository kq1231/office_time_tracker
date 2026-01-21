import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/work_session.dart';
import '../../utils/time_formatter.dart';
import '../constants/app_colors.dart';

/// Card widget that displays today's work hours with progress
class TodayHoursCard extends StatelessWidget {
  final double todayHours;
  final List<WorkSession> todaySessions;
  final WorkSession? activeSession;
  final double requiredHours;

  const TodayHoursCard({
    super.key,
    required this.todayHours,
    required this.todaySessions,
    required this.activeSession,
    this.requiredHours = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate real-time today's hours if there's an active session
    double realtimeTodayHours = todayHours;
    if (activeSession != null) {
      // Calculate non-active sessions' hours
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

      realtimeTodayHours = nonActiveHours + activeHours;
    }

    final percentage = (realtimeTodayHours / requiredHours).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: AppColors.getInfoColor(context),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Today\'s Hours',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  TimeFormatter.formatHours(realtimeTodayHours),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getInfoColor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'of $requiredHours hours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor:
                    AppColors.getProgressBarBackgroundColor(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                  realtimeTodayHours >= requiredHours
                      ? AppColors.getSuccessColor(context)
                      : AppColors.getInfoColor(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (todaySessions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sessions Today:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...todaySessions.map(
                (session) => _SessionRow(session: session),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final WorkSession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final clockIn = timeFormat.format(session.clockIn);
    final clockOut = session.clockOut != null
        ? timeFormat.format(session.clockOut!)
        : 'Active';
    final duration = TimeFormatter.formatDuration(session.durationSeconds);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            session.isActive ? Icons.radio_button_checked : Icons.check_circle,
            size: 16,
            color: session.isActive
                ? AppColors.getSuccessColor(context)
                : AppColors.getInfoColor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$clockIn - $clockOut',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getInfoColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
