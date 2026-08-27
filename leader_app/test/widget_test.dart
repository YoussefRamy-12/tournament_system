import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:leader_app/main.dart';
import 'package:leader_app/services/storage_service.dart';
import 'package:leader_app/services/api_service.dart';
import 'package:leader_app/providers/settings_provider.dart';
import 'package:leader_app/providers/auth_provider.dart';
import 'package:leader_app/providers/tournament_provider.dart';
import 'package:leader_app/providers/connectivity_provider.dart';

void main() {
  testWidgets('TournamentApp renders basic smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: storageService),
          Provider.value(value: apiService),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: storageService, api: apiService),
          ),
          ChangeNotifierProxyProvider<SettingsProvider, AuthProvider>(
            create: (_) => AuthProvider(api: apiService, storage: storageService),
            update: (_, settings, auth) => auth ?? AuthProvider(api: apiService, storage: storageService),
          ),
          ChangeNotifierProvider(
            create: (_) => ConnectivityProvider(storage: storageService),
          ),
          ChangeNotifierProxyProvider2<ConnectivityProvider, SettingsProvider, TournamentProvider>(
            create: (_) => TournamentProvider(api: apiService, storage: storageService),
            update: (_, conn, settings, tournament) => tournament ?? TournamentProvider(api: apiService, storage: storageService),
          ),
        ],
        child: const TournamentApp(),
      ),
    );
    expect(find.byType(TournamentApp), findsOneWidget);
  });
}
