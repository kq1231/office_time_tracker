import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_time_tracker/common/logging/app_logger.dart';
import '../models/work_session.dart';
import '../repositories/work_session_repository.dart';
import '../services/notification_service.dart';
import 'notification_service_provider.dart';
import 'work_session_repository_provider.dart';

/// State class for time tracking
class TimeTrackingState {
  final WorkSession? activeSession;
  final List<WorkSession> todaySessions;
  final double todayHours;
  final double totalBalance;

  TimeTrackingState({
    this.activeSession,
    this.todaySessions = const [],
    this.todayHours = 0.0,
    this.totalBalance = 0.0,
  });

  TimeTrackingState copyWith({
    WorkSession? activeSession,
    List<WorkSession>? todaySessions,
    double? todayHours,
    double? totalBalance,
  }) {
    return TimeTrackingState(
      activeSession: activeSession ?? this.activeSession,
      todaySessions: todaySessions ?? this.todaySessions,
      todayHours: todayHours ?? this.todayHours,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }
}

/// AsyncNotifier for time tracking operations
class TimeTrackingNotifier extends AsyncNotifier<TimeTrackingState> {
  WorkSessionRepositoryNotifier get _repository =>
      ref.read(workSessionRepositoryProvider.notifier);

  Future<NotificationService> get _notificationService async =>
      await ref.read(notificationServiceProvider.future);

  @override
  Future<TimeTrackingState> build() async {
    return await _loadData();
  }

  Future<TimeTrackingState> _loadData() async {
    final activeSession = await _repository.getActiveSession();
    final todaySessions = await _repository.getSessionsForDate(DateTime.now());
    final totalBalance = await _repository.calculateBalance();

    final todayHours = todaySessions.fold<double>(0.0, (sum, session) {
      return sum + session.durationHours;
    });

    return TimeTrackingState(
      activeSession: activeSession,
      todaySessions: todaySessions,
      todayHours: todayHours,
      totalBalance: totalBalance,
    );
  }

  /// Refresh data (with loading state)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _loadData());
  }

  /// Clock in
  Future<void> clockIn() async {
    await _repository.clockIn();
    final newState = await _loadData();
    state = AsyncValue.data(newState);

    // Schedule notifications if today's hours < 9
    try {
      await _scheduleNotificationsIfNeeded(newState);
    } catch (e) {
      AppLogger.error('Error scheduling notifications: $e');
    }
  }

  /// Clock out
  Future<void> clockOut() async {
    await _repository.clockOut();
    state = AsyncValue.data(await _loadData());

    // Cancel notifications when clocking out
    final notificationService = await _notificationService;
    await notificationService.cancelNineHourReminders();
  }

  /// Create custom session
  Future<void> createCustomSession({
    required DateTime date,
    required DateTime clockIn,
    DateTime? clockOut,
  }) async {
    await _repository.createCustomSession(
      date: date,
      clockIn: clockIn,
      clockOut: clockOut,
    );
    final newState = await _loadData();
    state = AsyncValue.data(newState);

    // Schedule notifications if it's an active session and today's hours < 9
    if (clockOut == null) {
      try {
        await _scheduleNotificationsIfNeeded(newState);
      } catch (e) {
        AppLogger.error('Error scheduling notifications: $e');
      }
    }
  }

  /// Update session
  Future<void> updateSession(WorkSession session) async {
    await _repository.updateSession(session);
    state = AsyncValue.data(await _loadData());
  }

  /// Delete session
  Future<void> deleteSession(int sessionId) async {
    await _repository.deleteSession(sessionId);
    state = AsyncValue.data(await _loadData());
  }

  /// Schedule notifications if needed (hours < 9 and active session exists)
  Future<void> _scheduleNotificationsIfNeeded(TimeTrackingState state) async {
    if (state.activeSession == null) return;

    // Calculate today's hours excluding the active session
    final todayHoursWithoutActive = state.todaySessions
        .where((s) => s.id != state.activeSession!.id && !s.isActive)
        .fold<double>(0.0, (sum, session) => sum + session.durationHours);

    // Only schedule if less than 9 hours worked (excluding current active session)
    if (todayHoursWithoutActive < 9.0) {
      final notificationService = await _notificationService;
      await notificationService.scheduleNineHourReminders(
        currentTodayHours: todayHoursWithoutActive,
      );
    }
  }
}

/// Provider instance
final timeTrackingProvider =
    AsyncNotifierProvider<TimeTrackingNotifier, TimeTrackingState>(() {
      return TimeTrackingNotifier();
    });
