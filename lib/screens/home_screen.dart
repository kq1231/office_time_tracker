import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/widgets/balance_card.dart';
import '../common/widgets/status_card.dart';
import '../common/widgets/today_hours_card.dart';
import '../providers/time_tracking_provider.dart';
import '../widgets/custom_session_dialog.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Office Time Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddCustomSessionDialog(context, ref),
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
      body: const _HomeContent(),
    );
  }
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
              StatusCard(
                activeSession: state.activeSession,
                pulseController: _pulseController,
              ),
              const SizedBox(height: 16),

              // Today's Hours Card
              TodayHoursCard(
                todayHours: state.todayHours,
                todaySessions: state.todaySessions,
                activeSession: state.activeSession,
              ),
              const SizedBox(height: 16),

              // Balance Card
              BalanceCard(
                totalBalance: state.totalBalance,
                todayHours: state.todayHours,
                activeSession: state.activeSession,
                todaySessions: state.todaySessions,
                pulseController: _pulseController,
              ),
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
}
