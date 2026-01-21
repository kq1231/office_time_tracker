import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/objectbox_service.dart';

/// Provider for ObjectBox service
final objectBoxServiceProvider = FutureProvider<ObjectBoxService>((ref) async {
  return await ObjectBoxService.create();
});
