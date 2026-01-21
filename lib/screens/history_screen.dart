import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/work_session.dart';
import '../providers/history_provider.dart';
import '../providers/time_tracking_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Work History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCustomSessionDialog(context),
            tooltip: 'Add Custom Session',
          ),
        ],
      ),
      body: historyAsync.when(
        data: (historyState) {
          if (historyState.dates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No work history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clock in to start tracking!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(historyProvider.notifier).refresh();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  historyState.dates.length +
                  (historyState.hasMore || historyState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == historyState.dates.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: historyState.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final date = historyState.dates[index];
                final sessions = historyState.sessionsByDate[date] ?? [];
                return _DateCard(
                  date: date,
                  sessions: sessions,
                  onEdit: (session) => _showEditSessionDialog(context, session),
                  onDelete: (session) =>
                      _confirmDeleteSession(context, session),
                );
              },
            ),
          );
        },
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
                onPressed: () => ref.invalidate(historyProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomSessionDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
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

                await ref.read(historyProvider.notifier).refresh();

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

  Future<void> _showEditSessionDialog(
    BuildContext context,
    WorkSession session,
  ) async {
    TimeOfDay clockIn = TimeOfDay.fromDateTime(session.clockIn);
    TimeOfDay? clockOut = session.clockOut != null
        ? TimeOfDay.fromDateTime(session.clockOut!)
        : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Clock In'),
                subtitle: Text(clockIn.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: clockIn,
                  );
                  if (time != null) {
                    setState(() => clockIn = time);
                  }
                },
              ),
              ListTile(
                title: const Text('Clock Out'),
                subtitle: Text(clockOut?.format(context) ?? 'Active'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: clockOut ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => clockOut = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedClockIn = DateTime(
                  session.date.year,
                  session.date.month,
                  session.date.day,
                  clockIn.hour,
                  clockIn.minute,
                );

                DateTime? updatedClockOut;
                if (clockOut != null) {
                  updatedClockOut = DateTime(
                    session.date.year,
                    session.date.month,
                    session.date.day,
                    clockOut!.hour,
                    clockOut!.minute,
                  );

                  if (updatedClockOut.isBefore(updatedClockIn)) {
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

                final updatedSession = WorkSession(
                  id: session.id,
                  date: session.date,
                  clockIn: updatedClockIn,
                  clockOut: updatedClockOut,
                );

                Navigator.pop(context);

                await ref
                    .read(timeTrackingProvider.notifier)
                    .updateSession(updatedSession);
                await ref.read(historyProvider.notifier).refresh();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WorkSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(timeTrackingProvider.notifier).deleteSession(session.id);
      await ref.read(historyProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session deleted!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DateCard extends ConsumerWidget {
  final DateTime date;
  final List<WorkSession> sessions;
  final Function(WorkSession) onEdit;
  final Function(WorkSession) onDelete;

  const _DateCard({
    required this.date,
    required this.sessions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalHours = sessions.fold<double>(
      0.0,
      (sum, session) => sum + session.durationHours,
    );
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
                Icon(Icons.calendar_today, size: 20, color: Colors.blue[700]),
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
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Total: ',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Sessions list with edit/delete buttons
            ...sessions.map((session) {
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onEdit(session),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onDelete(session),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
