import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// Provider for Notification service
final notificationServiceProvider = FutureProvider<NotificationService>((
  ref,
) async {
  final service = NotificationService();
  await service.initialize();
  await service.requestPermissions();

  return service;
});
