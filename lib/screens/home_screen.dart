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
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCustomSessionDialog(context, ref),
            tooltip: 'Add Custom Session',
          ),
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
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

Future<void> _showAddCustomSessionDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime selectedDate = today;
  TimeOfDay selectedClockIn = TimeOfDay.now();
  TimeOfDay? selectedClockOut; // Null by default

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Custom Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Clock In'),
                subtitle: Text(selectedClockIn.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedClockIn,
                  );
                  if (time != null) {
                    setState(() => selectedClockIn = time);
                  }
                },
              ),
              ListTile(
                title: const Text('Clock Out'),
                subtitle: Text(
                  selectedClockOut?.format(context) ?? 'In Progress',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedClockOut != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setState(() => selectedClockOut = null),
                        tooltip: 'Clear (In Progress)',
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedClockOut ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => selectedClockOut = time);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final clockIn = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedClockIn.hour,
                selectedClockIn.minute,
              );

              DateTime? clockOut;
              if (selectedClockOut != null) {
                clockOut = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedClockOut!.hour,
                  selectedClockOut!.minute,
                );

                if (clockOut.isBefore(clockIn)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clock out must be after clock in!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

              Navigator.pop(context);

              await ref
                  .read(timeTrackingProvider.notifier)
                  .createCustomSession(
                    date: selectedDate,
                    clockIn: clockIn,
                    clockOut: clockOut,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      clockOut == null
                          ? 'Active session started!'
                          : 'Custom session added!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startRealtimeTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startRealtimeTimer() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          // Trigger rebuild every second to update real-time displays
        });
        _startRealtimeTimer();
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

    // Calculate real-time elapsed duration
    int totalSeconds = 0;
    if (isActive && state.activeSession != null) {
      totalSeconds = DateTime.now()
          .difference(state.activeSession!.clockIn)
          .inSeconds;
    }

    return Card(
      color: isActive ? Colors.green[50] : Colors.grey[50],
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
                ).animate(_pulseController),
                child: Icon(Icons.schedule, size: 48, color: Colors.green),
              )
            else
              Icon(Icons.schedule_outlined, size: 48, color: Colors.grey),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              // Real-time elapsed time with seconds
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 20, color: Colors.green[700]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(totalSeconds),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _buildTodayCard(BuildContext context, TimeTrackingState state) {
    // Calculate real-time today's hours if there's an active session
    double realtimeTodayHours = state.todayHours;
    if (state.activeSession != null) {
      // Calculate non-active sessions' hours
      final nonActiveHours = state.todaySessions
          .where((s) => s.id != state.activeSession!.id)
          .fold<double>(
            0.0,
            (sum, s) =>
                sum + (s.clockOut!.difference(s.clockIn).inMinutes / 60.0),
          );

      // Calculate real-time active session hours
      final activeSeconds = DateTime.now()
          .difference(state.activeSession!.clockIn)
          .inSeconds;
      final activeHours = activeSeconds / 3600.0;

      realtimeTodayHours = nonActiveHours + activeHours;
    }

    const requiredHours = 9.0;
    final percentage = (realtimeTodayHours / requiredHours).clamp(0.0, 1.0);

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
                  _formatHours(realtimeTodayHours),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'of $requiredHours hours',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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
                  realtimeTodayHours >= requiredHours
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (state.todaySessions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sessions Today:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...state.todaySessions.map(
                (session) => _buildSessionRow(session),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow(WorkSession session) {
    final timeFormat = DateFormat('h:mm a');
    final clockIn = timeFormat.format(session.clockIn);
    final clockOut = session.clockOut != null
        ? timeFormat.format(session.clockOut!)
        : 'Active';
    final duration = _formatDuration(session.durationSeconds);

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
    // Calculate real-time balance with active session
    double realtimeBalance = state.totalBalance;
    if (state.activeSession != null) {
      // Calculate non-active sessions' hours for today
      final nonActiveHours = state.todaySessions
          .where((s) => s.id != state.activeSession!.id)
          .fold<double>(
            0.0,
            (sum, s) =>
                sum + (s.clockOut!.difference(s.clockIn).inMinutes / 60.0),
          );

      // Calculate real-time active session hours
      final activeSeconds = DateTime.now()
          .difference(state.activeSession!.clockIn)
          .inSeconds;
      final activeHours = activeSeconds / 3600.0;

      // Recalculate today's total with real-time active session
      final realtimeTodayHours = nonActiveHours + activeHours;

      // Adjust balance: remove old today's hours, add real-time today's hours
      realtimeBalance =
          state.totalBalance - state.todayHours + realtimeTodayHours;
    }

    final isPositive = realtimeBalance >= 0;
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
                if (state.activeSession != null)
                  FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.3,
                      end: 1.0,
                    ).animate(_pulseController),
                    child: Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: color[700],
                      size: 32,
                    ),
                  )
                else
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
            // Show real-time balance with seconds precision when active
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isPositive ? '+' : ''}${_formatHours(realtimeBalance)}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color[700],
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (state.activeSession != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 20, color: color[700]),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPositive
                  ? state.activeSession != null
                        ? 'Balance growing! Keep it up! 🚀'
                        : 'You are ahead! Great job! 🎉'
                  : state.activeSession != null
                  ? 'Working to catch up! 💪'
                  : 'You need to catch up 💪',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: color[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockButton(BuildContext context, TimeTrackingState state) {
    final isActive = state.activeSession != null;

    return ElevatedButton(
      onPressed: () async {
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
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isActive ? Icons.logout : Icons.login, size: 28),
          const SizedBox(width: 12),
          Text(
            isActive ? 'Clock Out' : 'Clock In',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h == 0) {
      return '${m}m';
    }
    if (m == 0) {
      return '${h}h';
    }
    if (s == 0) {
      return '${h}h ${m}m';
    }
    return '${h}h ${m}m ${s}s';
  }
}
