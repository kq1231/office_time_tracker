import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:office_time_tracker/models/work_session.dart';
import '../providers/objectbox_provider.dart';
import '../providers/time_tracking_provider.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectBoxAsync = ref.watch(objectBoxServiceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Office Time Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: objectBoxAsync.when(
        data: (_) => const _HomeContent(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  @override
  void initState() {
    super.initState();
    // Refresh every minute to update active session duration
    Future.delayed(const Duration(seconds: 1), _startTimer);
  }

  void _startTimer() {
    if (!mounted) return;
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        ref.read(timeTrackingProvider.notifier).refresh();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(timeTrackingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(timeTrackingProvider.notifier).refresh();
      },
      child: stateAsync.when(
        data: (state) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Status Card
              _buildStatusCard(context, state),
              const SizedBox(height: 16),

              // Today's Hours Card
              _buildTodayCard(context, state),
              const SizedBox(height: 16),

              // Balance Card
              _buildBalanceCard(context, state),
              const SizedBox(height: 24),

              // Clock In/Out Button
              _buildClockButton(context, state),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(timeTrackingProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, TimeTrackingState state) {
    final isActive = state.activeSession != null;
    final timeFormat = DateFormat('h:mm a');

    return Card(
      color: isActive ? Colors.green[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isActive ? Icons.schedule : Icons.schedule_outlined,
              size: 48,
              color: isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'Currently Clocked In' : 'Not Clocked In',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                  ),
            ),
            if (isActive && state.activeSession != null) ...[
              const SizedBox(height: 8),
              Text(
                'Since ${timeFormat.format(state.activeSession!.clockIn)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(state.activeSession!.durationMinutes)} elapsed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context, TimeTrackingState state) {
    final todayHours = state.todayHours;
    const requiredHours = 9.0;
    final percentage = (todayHours / requiredHours).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue[700]),
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
                  _formatHours(todayHours),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'of $requiredHours hours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
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
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  todayHours >= requiredHours ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (state.todaySessions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sessions Today:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...state.todaySessions.map((session) => _buildSessionRow(session)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow(WorkSession session) {
    final timeFormat = DateFormat('h:mm a');
    final clockIn = timeFormat.format(session.clockIn);
    final clockOut =
        session.clockOut != null ? timeFormat.format(session.clockOut!) : 'Active';
    final duration = _formatDuration(session.durationMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            session.isActive ? Icons.radio_button_checked : Icons.check_circle,
            size: 16,
            color: session.isActive ? Colors.green : Colors.blue,
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
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, TimeTrackingState state) {
    final balance = state.totalBalance;
    final isPositive = balance >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      color: color[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color[700],
                  size: 32,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Total Balance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color[700],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${isPositive ? '+' : ''}${_formatHours(balance)}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isPositive
                  ? 'You are ahead! Great job! 🎉'
                  : 'You need to catch up 💪',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockButton(BuildContext context, TimeTrackingState state) {
    final isActive = state.activeSession != null;
    final asyncState = ref.watch(timeTrackingProvider);
    final isLoading = asyncState.isLoading;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              try {
                if (isActive) {
                  await ref.read(timeTrackingProvider.notifier).clockOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clocked out successfully! ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  await ref.read(timeTrackingProvider.notifier).clockIn();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clocked in successfully! ⏰'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: isLoading
          ? const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.logout : Icons.login,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isActive ? 'Clock Out' : 'Clock In',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) {
      return '${m}m';
    }
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }
}
