import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/work_session_repository.dart';
import 'objectbox_provider.dart';

/// Provider for WorkSessionRepository
final workSessionRepositoryProvider = Provider<WorkSessionRepository>((ref) {
  final objectBoxService = ref.watch(objectBoxServiceProvider).requireValue;
  return WorkSessionRepository(objectBoxService.store);
});
