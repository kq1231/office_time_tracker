import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/providers/objectbox_store_provider.dart';
import '../../common/providers/notification_service_provider.dart';

/// Provider that handles app startup initialization
/// Initializes ObjectBox and Notification Service
final appStartupProvider = FutureProvider<void>((ref) async {
  // Wait for both services to initialize
  await ref.watch(objectBoxStoreProvider.future);
  await ref.watch(notificationServiceProvider.future);
});
