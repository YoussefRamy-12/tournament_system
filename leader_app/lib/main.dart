import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/network/connection_manager.dart';
import 'package:leader_app/network/settings_provider.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/member_selector.dart';
import 'package:leader_app/ui/my_home_page.dart';
import 'package:leader_app/ui/registration_screen.dart';
import 'package:leader_app/ui/scanner_screen.dart';
import 'package:leader_app/ui/waiting_approval_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check if we have a saved connection
  final connection = ConnectionManager();
  String? savedUrl = await connection.getUrl();

  final bool isRegistered = await connection.isRegistered();
  final apiClient = ApiClient();
  if (savedUrl != null) apiClient.connectWebSocket(); // Start heartbeat
  Widget initialScreen;

  if (savedUrl != null && isRegistered) {
    try {
      // 2. Ping the saved URL to see if it's still valid
      bool available = await apiClient.isServerAvailable();

      if (!available) {
        // 3. Search for the server ONCE during startup
        await apiClient.findNewServerIP();
      }
    } catch (e) {
      print("⚠️ Connection failed during startup: $e");
    }
  }

  if (savedUrl == null) {
    initialScreen = const ScannerScreen();
  } else if (!isRegistered) {
    initialScreen = const RegistrationScreen();
  } else {
    initialScreen = const MyHomePage(title: "test");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tournament Leader',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            ),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontSizeFactor),
                ),
                child: child!,
              );
            },
            home: initialScreen,
            routes: {
              '/scanner': (context) => const ScannerScreen(),
              '/home': (context) => const MyHomePage(title: 'test'),
              '/member_selector': (context) => const MemberSelector(),
              '/registration': (context) => const RegistrationScreen(),
              '/waiting_approval': (context) => const WaitingApprovalScreen(),
            },
          );
        },
      ),
    ),
  );
}
