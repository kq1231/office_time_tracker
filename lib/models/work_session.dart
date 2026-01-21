import 'package:objectbox/objectbox.dart';

/// Represents a single work session (clock in + clock out)
@Entity()
class WorkSession {
  @Id()
  int id = 0;

  /// Date of this session (normalized to start of day)
  @Property(type: PropertyType.date)
  DateTime date;

  /// Clock in time
  @Property(type: PropertyType.date)
  DateTime clockIn;

  /// Clock out time (null if still active)
  @Property(type: PropertyType.date)
  DateTime? clockOut;

  /// Duration in minutes
  int get durationMinutes {
    if (clockOut == null) {
      // If still active, calculate duration until now
      return DateTime.now().difference(clockIn).inMinutes;
    }
    return clockOut!.difference(clockIn).inMinutes;
  }

  /// Duration in hours (with decimals)
  double get durationHours => durationMinutes / 60.0;

  /// Whether this session is still active
  bool get isActive => clockOut == null;

  WorkSession({
    this.id = 0,
    required this.date,
    required this.clockIn,
    this.clockOut,
  });
}
