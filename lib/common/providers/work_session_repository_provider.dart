import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/work_session_repository.dart';

/// Provider for WorkSessionRepository
final workSessionRepositoryProvider =
    AsyncNotifierProvider<WorkSessionRepositoryNotifier, void>(() {
      return WorkSessionRepositoryNotifier();
    });
