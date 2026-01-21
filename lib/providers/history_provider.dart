import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_session.dart';
import '../repositories/work_session_repository.dart';
import 'repository_provider.dart';

/// State class for history with pagination
class HistoryState {
  final Map<DateTime, List<WorkSession>> sessionsByDate;
  final List<DateTime> dates;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalSessions;

  HistoryState({
    this.sessionsByDate = const {},
    this.dates = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.totalSessions = 0,
  });

  HistoryState copyWith({
    Map<DateTime, List<WorkSession>>? sessionsByDate,
    List<DateTime>? dates,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalSessions,
  }) {
    return HistoryState(
      sessionsByDate: sessionsByDate ?? this.sessionsByDate,
      dates: dates ?? this.dates,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}

/// Notifier for history with pagination
class HistoryNotifier extends AsyncNotifier<HistoryState> {
  WorkSessionRepository get _repository =>
      ref.read(workSessionRepositoryProvider);

  static const int _pageSize = 20;
  int _currentOffset = 0;

  @override
  Future<HistoryState> build() async {
    _currentOffset = 0;
    return await _loadInitialData();
  }

  Future<HistoryState> _loadInitialData() async {
    final totalCount = await _repository.getSessionCount();
    final sessions = await _repository.getSessionsPaginated(
      offset: 0,
      limit: _pageSize,
    );

    final sessionsByDate = _groupSessionsByDate(sessions);
    final dates = sessionsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending

    _currentOffset = _pageSize;

    return HistoryState(
      sessionsByDate: sessionsByDate,
      dates: dates,
      hasMore: sessions.length >= _pageSize && _currentOffset < totalCount,
      totalSessions: totalCount,
    );
  }

  /// Load more sessions
  Future<void> loadMore() async {
    final currentStateValue = state.value;
    if (currentStateValue == null ||
        currentStateValue.isLoadingMore ||
        !currentStateValue.hasMore) {
      return;
    }

    // Set loading more flag
    state = AsyncValue.data(currentStateValue.copyWith(isLoadingMore: true));

    try {
      final newSessions = await _repository.getSessionsPaginated(
        offset: _currentOffset,
        limit: _pageSize,
      );

      if (newSessions.isEmpty) {
        state = AsyncValue.data(
          currentStateValue.copyWith(hasMore: false, isLoadingMore: false),
        );
        return;
      }

      // Merge new sessions with existing ones
      final updatedSessionsByDate = Map<DateTime, List<WorkSession>>.from(
        currentStateValue.sessionsByDate,
      );

      for (final session in newSessions) {
        final date = session.date;
        if (updatedSessionsByDate.containsKey(date)) {
          updatedSessionsByDate[date]!.add(session);
        } else {
          updatedSessionsByDate[date] = [session];
        }
      }

      final updatedDates = updatedSessionsByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      _currentOffset += _pageSize;

      state = AsyncValue.data(
        HistoryState(
          sessionsByDate: updatedSessionsByDate,
          dates: updatedDates,
          hasMore:
              newSessions.length >= _pageSize &&
              _currentOffset < currentStateValue.totalSessions,
          isLoadingMore: false,
          totalSessions: currentStateValue.totalSessions,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(currentStateValue.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh entire history
  Future<void> refresh() async {
    _currentOffset = 0;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _loadInitialData());
  }

  /// Helper to group sessions by date
  Map<DateTime, List<WorkSession>> _groupSessionsByDate(
    List<WorkSession> sessions,
  ) {
    final Map<DateTime, List<WorkSession>> grouped = {};

    for (final session in sessions) {
      final date = session.date;
      if (grouped.containsKey(date)) {
        grouped[date]!.add(session);
      } else {
        grouped[date] = [session];
      }
    }

    // Sort sessions within each date by clockIn time
    for (final date in grouped.keys) {
      grouped[date]!.sort((a, b) => a.clockIn.compareTo(b.clockIn));
    }

    return grouped;
  }
}

/// Provider instance
final historyProvider =
    AsyncNotifierProvider.autoDispose<HistoryNotifier, HistoryState>(() {
      return HistoryNotifier();
    });
