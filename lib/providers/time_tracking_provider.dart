import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_session.dart';
import '../repositories/work_session_repository.dart';
import 'repository_provider.dart';

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
  WorkSessionRepository get _repository =>
      ref.read(workSessionRepositoryProvider);

  @override
  Future<TimeTrackingState> build() async {
    return await _loadData();
  }

  Future<TimeTrackingState> _loadData() async {
    final activeSession = await _repository.getActiveSession();
    final todaySessions = await _repository.getSessionsForDate(DateTime.now());
    final todayHours = await _repository.getTotalHoursForDate(DateTime.now());
    final totalBalance = await _repository.calculateBalance();

    return TimeTrackingState(
      activeSession: activeSession,
      todaySessions: todaySessions,
      todayHours: todayHours,
      totalBalance: totalBalance,
    );
  }

  /// Refresh data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _loadData());
  }

  /// Clock in
  Future<void> clockIn() async {
    await _repository.clockIn();
    await refresh();
  }

  /// Clock out
  Future<void> clockOut() async {
    await _repository.clockOut();
    await refresh();
  }

  /// Get sessions for a specific date
  Future<List<WorkSession>> getSessionsForDate(DateTime date) async {
    return await _repository.getSessionsForDate(date);
  }

  /// Get total hours for a specific date
  Future<double> getHoursForDate(DateTime date) async {
    return await _repository.getTotalHoursForDate(date);
  }

  /// Get all dates with sessions
  Future<List<DateTime>> getAllDates() async {
    return await _repository.getAllDates();
  }
}

/// Provider instance
final timeTrackingProvider =
    AsyncNotifierProvider<TimeTrackingNotifier, TimeTrackingState>(() {
  return TimeTrackingNotifier();
});
