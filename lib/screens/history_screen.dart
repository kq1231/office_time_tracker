import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/time_tracking_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<DateTime>? _allDates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() => _isLoading = true);
    try {
      final dates =
          await ref.read(timeTrackingProvider.notifier).getAllDates();
      if (mounted) {
        setState(() {
          _allDates = dates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Work History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_allDates == null || _allDates!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No work history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clock in to start tracking!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allDates!.length,
                    itemBuilder: (context, index) {
                      final date = _allDates![index];
                      return _DateCard(date: date);
                    },
                  ),
                ),
    );
  }
}

class _DateCard extends ConsumerWidget {
  final DateTime date;

  const _DateCard({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_DateData>(
      future: _loadDateData(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data!;
        final totalHours = data.totalHours;
        const requiredHours = 9.0;
        final difference = totalHours - requiredHours;
        final isPositive = difference >= 0;

        final dateFormat = DateFormat('EEEE, MMM d, y');
        final timeFormat = DateFormat('h:mm a');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateFormat.format(date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Balance badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${_formatHours(difference)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total hours
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatHours(totalHours),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      ' of $requiredHours hours',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Sessions list
                ...data.sessions.map((session) {
                  final clockIn = timeFormat.format(session.clockIn);
                  final clockOut = session.clockOut != null
                      ? timeFormat.format(session.clockOut!)
                      : 'Active';
                  final duration = _formatDuration(session.durationMinutes);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          session.isActive
                              ? Icons.radio_button_checked
                              : Icons.check_circle_outline,
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_DateData> _loadDateData(WidgetRef ref) async {
    final notifier = ref.read(timeTrackingProvider.notifier);
    final sessions = await notifier.getSessionsForDate(date);
    final totalHours = await notifier.getHoursForDate(date);
    return _DateData(sessions: sessions, totalHours: totalHours);
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

class _DateData {
  final List sessions;
  final double totalHours;

  _DateData({required this.sessions, required this.totalHours});
}
