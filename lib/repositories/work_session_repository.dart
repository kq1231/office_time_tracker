import '../models/work_session.dart';
import '../objectbox.g.dart';

/// Repository for managing work session data operations
class WorkSessionRepository {
  final Box<WorkSession> _sessionBox;

  WorkSessionRepository(Store store) : _sessionBox = store.box<WorkSession>();

  /// Get all sessions
  Future<List<WorkSession>> getAllSessions() async {
    return await _sessionBox.getAllAsync();
  }

  /// Get all dates with sessions
  Future<List<DateTime>> getAllDates() async {
    final allSessions = await getAllSessions();
    return allSessions.map((s) => s.date).toSet().toList();
  }

  /// Get sessions for a specific date
  Future<List<WorkSession>> getSessionsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _sessionBox
        .query(
          WorkSession_.date.greaterOrEqual(startOfDay.millisecondsSinceEpoch) &
              WorkSession_.date.lessThan(endOfDay.millisecondsSinceEpoch),
        )
        .order(WorkSession_.clockIn)
        .build();

    final sessions = await query.findAsync();
    query.close();
    return sessions;
  }

  /// Get active session (one that hasn't been clocked out yet)
  Future<WorkSession?> getActiveSession() async {
    final query = _sessionBox
        .query(WorkSession_.clockOut.isNull())
        .order(WorkSession_.clockIn, flags: Order.descending)
        .build();

    final sessions = await query.findAsync();
    query.close();
    return sessions.isEmpty ? null : sessions.first;
  }

  /// Clock in - create a new session
  Future<WorkSession> clockIn() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final session = WorkSession(date: startOfDay, clockIn: now);

    session.id = await _sessionBox.putAsync(session);
    return session;
  }

  /// Clock out - update the active session
  Future<WorkSession?> clockOut() async {
    final activeSession = await getActiveSession();
    if (activeSession == null) return null;

    activeSession.clockOut = DateTime.now();
    await _sessionBox.putAsync(activeSession);
    return activeSession;
  }

  /// Get total hours worked on a specific date
  Future<double> getTotalHoursForDate(DateTime date) async {
    final sessions = await getSessionsForDate(date);
    return sessions.fold<double>(
      0.0,
      (sum, session) => sum + session.durationHours,
    );
  }

  /// Calculate balance (total hours - required hours)
  Future<double> calculateBalance() async {
    // Get all sessions
    final allSessions = await getAllSessions();
    // Get all dates
    final allDates = allSessions.map((s) => s.date).toSet().toList();
    // Get total hours
    final totalHours = allSessions.fold<double>(
      0.0,
      (sum, session) => sum + session.durationHours,
    );
    // Get required hours
    final requiredHours = allDates.length * 9.0;
    // Return balance
    return totalHours - requiredHours;
  }
}
