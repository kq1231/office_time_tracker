import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/objectbox_service.dart';

/// Record to hold all initialized services
class AppStartupData {
  final ObjectBoxService objectBoxService;
  final NotificationService notificationService;

  const AppStartupData({
    required this.objectBoxService,
    required this.notificationService,
  });
}

/// Provider that handles app startup initialization
/// Initializes ObjectBox and Notification Service
final appStartupProvider = FutureProvider<AppStartupData>((ref) async {
  // Initialize ObjectBox
  final objectBoxService = await ObjectBoxService.create();

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Keep the services alive
  ref.onDispose(() {
    objectBoxService.close();
  });

  return AppStartupData(
    objectBoxService: objectBoxService,
    notificationService: notificationService,
  );
});

/// Provider for ObjectBox service (derived from app startup)
final objectBoxServiceProvider = Provider<ObjectBoxService>((ref) {
  final appStartup = ref.watch(appStartupProvider);
  return appStartup.maybeWhen(
    data: (data) => data.objectBoxService,
    orElse: () => throw Exception('ObjectBox not initialized yet'),
  );
});

/// Provider for Notification service (derived from app startup)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final appStartup = ref.watch(appStartupProvider);
  return appStartup.maybeWhen(
    data: (data) => data.notificationService,
    orElse: () => throw Exception('NotificationService not initialized yet'),
  );
});
