import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_time_tracker/objectbox.g.dart';
import '../services/objectbox_service.dart';

/// Provider for ObjectBox service
final objectBoxStoreProvider = FutureProvider<Store>((ref) async {
  final store = await ObjectBoxService.create();

  // Close the store on dispose
  ref.onDispose(() {
    store.close();
  });

  return store;
});
