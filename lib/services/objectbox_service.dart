import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';

/// Service responsible for creating and providing ObjectBox Store
class ObjectBoxService {
  final Store store;

  ObjectBoxService._(this.store);

  /// Create ObjectBox service with initialized store
  static Future<ObjectBoxService> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, 'office_time_tracker'));
    return ObjectBoxService._(store);
  }

  /// Close the store
  void close() {
    store.close();
  }
}
