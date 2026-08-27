// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/storage_service.dart';
import 'package:admin_app/providers/settings_provider.dart';
import 'package:admin_app/providers/dashboard_provider.dart';

void main() {
  testWidgets('MyApp renders basic smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: storageService),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: storageService),
          ),
          ChangeNotifierProvider(
            create: (_) => DashboardProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.byType(MyApp), findsOneWidget);
  });
}
