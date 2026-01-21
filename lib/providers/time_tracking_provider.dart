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
    final totalBalance = await _repository.calculateBalance();

    final todayHours = todaySessions.fold<double>(
      0.0,
      (sum, session) {
        return sum + session.durationHours;
      },
    );

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
    state = AsyncValue.data(await _loadData());
  }

  /// Clock out
  Future<void> clockOut() async {
    await _repository.clockOut();
    state = AsyncValue.data(await _loadData());
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
    state = AsyncValue.data(await _loadData());
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
}

/// Provider instance
final timeTrackingProvider =
    AsyncNotifierProvider<TimeTrackingNotifier, TimeTrackingState>(() {
  return TimeTrackingNotifier();
});