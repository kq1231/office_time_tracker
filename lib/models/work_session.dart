import 'package:objectbox/objectbox.dart';

/// Represents a single work session (clock in + clock out)
@Entity()
class WorkSession {
  @Id()
  int id = 0;

  /// Date of this session (normalized to start of day)
  DateTime date;

  /// Clock in time
  DateTime clockIn;

  /// Clock out time (null if still active)
  DateTime? clockOut;

  /// Duration in seconds
  int get durationSeconds {
    if (clockOut == null) {
      // If still active, calculate duration until now
      return DateTime.now().difference(clockIn).inSeconds;
    }
    return clockOut!.difference(clockIn).inSeconds;
  }

  /// Duration in hours (with decimals)
  double get durationHours => durationSeconds / 3600.0;

  /// Whether this session is still active
  bool get isActive => clockOut == null;

  WorkSession({
    this.id = 0,
    required this.date,
    required this.clockIn,
    this.clockOut,
  });

  @override
  String toString() {
    return 'WorkSession(id: $id, date: $date, clockIn: $clockIn, clockOut: $clockOut, durationSeconds: $durationSeconds, durationHours: $durationHours, isActive: $isActive)';
  }
}
