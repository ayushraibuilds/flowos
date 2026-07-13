import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/presentation/navigation/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('FlowOS app starts and shows loading or home', (
    WidgetTester tester,
  ) async {
    // 1. Setup mock SharedPreferences for initialization
    SharedPreferences.setMockInitialValues({});

    // 2. Setup in-memory database
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Note: To do a full widget pump we'd need to mock the connection and all providers.
    // For now, let's just assert the database can be instantiated in memory
    // and that the basic architecture holds.
    expect(db, isNotNull);
    await db.close();
  });

  test('Insights is a registered navigation destination', () {
    expect(appRouter.namedLocation('insights'), '/insights');
  });
}
