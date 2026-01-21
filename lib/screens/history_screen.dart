import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../common/constants/app_colors.dart';
import '../models/work_session.dart';
import '../providers/history_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/custom_session_dialog.dart';

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
            onPressed: () => showAddCustomSessionDialog(
              context,
              ref,
              onSuccess: () {
                ref.read(historyProvider.notifier).refresh();
              },
            ),
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
                  onEdit: (session) => showEditSessionDialog(
                    context,
                    ref,
                    session,
                    onSuccess: () {
                      ref.read(historyProvider.notifier).refresh();
                    },
                  ),
                  onDelete: (session) => showDeleteSessionDialog(
                    context,
                    ref,
                    session,
                    onSuccess: () {
                      ref.read(historyProvider.notifier).refresh();
                    },
                  ),
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
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.getInfoColor(context),
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
                    color: isPositive
                        ? AppColors.getBadgePositiveBackgroundColor(context)
                        : AppColors.getBadgeNegativeBackgroundColor(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${TimeFormatter.formatHours(difference)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? AppColors.getBadgePositiveColor(context)
                          : AppColors.getBadgeNegativeColor(context),
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
                  color: AppColors.getTextSecondaryColor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Total: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
                ),
                Flexible(
                  child: Text(
                    TimeFormatter.formatHours(totalHours),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getInfoColor(context),
                    ),
                  ),
                ),
                Text(
                  ' of $requiredHours hours',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondaryColor(context),
                  ),
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
              final duration = TimeFormatter.formatDuration(session.durationSeconds);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                  Icon(
                    session.isActive
                        ? Icons.radio_button_checked
                        : Icons.check_circle_outline,
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
}
