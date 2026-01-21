import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';

/// Service responsible for creating and providing ObjectBox Store
class ObjectBoxService {
  ObjectBoxService._();

  /// Create ObjectBox service with initialized store
  static Future<Store> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: p.join(docsDir.path, 'office_time_tracker'),
    );
    return store;
  }
}
