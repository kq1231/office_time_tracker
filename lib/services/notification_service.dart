import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:office_time_tracker/common/logging/app_logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service for managing local notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open App',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // For now, we'll just log it
    AppLogger.info('Notification tapped: ${response.id}');
  }

  /// Request notification permissions (mainly for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // For iOS
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // For Android 13+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();

    return granted ?? true;
  }

  /// Schedule notifications for 9-hour completion
  /// [currentTodayHours] - Hours already worked today (excluding active session)
  /// Returns true if notifications were scheduled successfully
  Future<bool> scheduleNineHourReminders({
    required double currentTodayHours,
  }) async {
    const requiredHours = 9.0;

    // If already worked 9+ hours, no need to schedule
    if (currentTodayHours >= requiredHours) {
      return false;
    }

    // Cancel any existing reminders
    await cancelNineHourReminders();

    // Calculate hours remaining
    final hoursRemaining = requiredHours - currentTodayHours;

    // Convert to duration
    final durationToComplete = Duration(
      hours: hoursRemaining.floor(),
      minutes: ((hoursRemaining - hoursRemaining.floor()) * 60).round(),
    );

    // Get the scheduled time (now + duration to complete)
    final now = DateTime.now();
    final completionTime = now.add(durationToComplete);

    // Schedule 10 minutes before
    if (durationToComplete.inMinutes > 10) {
      await _scheduleNotification(
        id: 100,
        title: '10 Minutes Until Goal! ⏰',
        body: 'You\'re 10 minutes away from completing your 9 hours today!',
        scheduledTime: completionTime.subtract(const Duration(minutes: 10)),
      );
    }

    // Schedule 5 minutes before
    if (durationToComplete.inMinutes > 5) {
      await _scheduleNotification(
        id: 101,
        title: '5 Minutes to Go! 🎯',
        body: 'Just 5 more minutes until you reach your 9-hour goal!',
        scheduledTime: completionTime.subtract(const Duration(minutes: 5)),
      );
    }

    // Schedule at completion
    await _scheduleNotification(
      id: 102,
      title: 'Goal Achieved! 🎉',
      body:
          'Congratulations! You\'ve completed your 9 hours for today. You may want to clock out.',
      scheduledTime: completionTime,
    );

    return true;
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();

    // Convert DateTime to TZDateTime
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'work_hours_channel',
      'Work Hours Notifications',
      channelDescription: 'Notifications for work hour tracking and reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel all 9-hour reminder notifications
  Future<void> cancelNineHourReminders() async {
    await _notifications.cancel(100); // 10 min reminder
    await _notifications.cancel(101); // 5 min reminder
    await _notifications.cancel(102); // Completion notification
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'work_hours_channel',
      'Work Hours Notifications',
      channelDescription: 'Notifications for work hour tracking and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(999, title, body, notificationDetails);
  }

  /// Get pending notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
