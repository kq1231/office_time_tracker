import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_session.dart';
import '../../utils/time_formatter.dart';
import '../constants/app_colors.dart';

/// Card widget that displays the current clock-in status
class StatusCard extends StatelessWidget {
  final WorkSession? activeSession;
  final AnimationController pulseController;

  const StatusCard({
    super.key,
    required this.activeSession,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeSession != null;
    final timeFormat = DateFormat('h:mm a');

    // Calculate real-time elapsed duration
    int totalSeconds = 0;
    if (isActive && activeSession != null) {
      totalSeconds = DateTime.now()
          .difference(activeSession!.clockIn)
          .inSeconds;
    }

    return Card(
      color: isActive
          ? AppColors.getSuccessBackgroundColor(context)
          : AppColors.getNeutralBackgroundColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Pulsing icon when active
            if (isActive)
              FadeTransition(
                opacity: Tween<double>(
                  begin: 0.5,
                  end: 1.0,
                ).animate(pulseController),
                child: Icon(
                  Icons.schedule,
                  size: 48,
                  color: AppColors.getSuccessColor(context),
                ),
              )
            else
              Icon(
                Icons.schedule_outlined,
                size: 48,
                color: AppColors.getNeutralColor(context),
              ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'Currently Clocked In' : 'Not Clocked In',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? AppColors.getSuccessColor(context)
                    : AppColors.getNeutralColor(context),
              ),
            ),
            if (isActive && activeSession != null) ...[
              const SizedBox(height: 8),
              Text(
                'Since ${timeFormat.format(activeSession!.clockIn)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              // Real-time elapsed time with seconds
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: AppColors.getSuccessColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    TimeFormatter.formatDuration(totalSeconds),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.getSuccessColor(context),
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
