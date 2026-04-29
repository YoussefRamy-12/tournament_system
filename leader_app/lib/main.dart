import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/connectivity_provider.dart';

import 'ui/app_localizations.dart';
import 'ui/member_selector.dart';
import 'ui/my_home_page.dart';
import 'ui/registration_screen.dart';
import 'ui/scanner_screen.dart';
import 'ui/waiting_approval_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storageService),
        Provider.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storage: storageService,
            api: apiService,
          ),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, AuthProvider>(
          create: (_) => AuthProvider(
            api: apiService,
            storage: storageService,
          ),
          update: (_, settings, auth) {
            auth!.onNameUpdated = (newName) {
              // Only update if it's actually different to avoid rebuild loops
              if (settings.leaderName != newName) {
                settings.setLeaderName(newName);
              }
            };
            return auth;
          },
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ConnectivityProvider>(
          create: (_) => ConnectivityProvider(
            storage: storageService,
          ),
          update: (_, settings, connectivity) {
            connectivity!.onProfileUpdate = (newName) {
              if (settings.leaderName != newName) {
                settings.setLeaderName(newName);
              }
            };
            return connectivity;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => TournamentProvider(
            api: apiService,
            storage: storageService,
          ),
        ),
      ],
      child: const TournamentApp(),
    ),
  );
}

class TournamentApp extends StatelessWidget {
  const TournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settings, auth, child) {
        if (auth.isInitializing) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        Widget initialScreen;
        switch (auth.status) {
          case AuthStatus.scanning:
          case AuthStatus.unauthenticated:
            initialScreen = const ScannerScreen();
            break;
          case AuthStatus.registering:
            initialScreen = const RegistrationScreen();
            break;
          case AuthStatus.waitingApproval:
            initialScreen = const WaitingApprovalScreen();
            break;
          case AuthStatus.approved:
            initialScreen = const MyHomePage(title: 'Home');
            break;
          case AuthStatus.error:
            initialScreen = const ScannerScreen(); // Fallback
            break;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tournament Leader',
          theme: AppTheme.lightTheme(settings.locale),
          darkTheme: AppTheme.darkTheme(settings.locale),
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
            if (child == null) return const SizedBox.shrink();
            child = ResponsiveBreakpoints.builder(
              child: child,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            );
            final mediaQueryData = MediaQuery.maybeOf(context) ?? const MediaQueryData();
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: TextScaler.linear(settings.fontSizeFactor),
              ),
              child: child,
            );
          },
          home: initialScreen,
          routes: {
            '/scanner': (context) => const ScannerScreen(),
            '/home': (context) => const MyHomePage(title: 'Home'),
            '/member_selector': (context) => const MemberSelector(),
            '/registration': (context) => const RegistrationScreen(),
            '/waiting_approval': (context) => const WaitingApprovalScreen(),
          },
        );
      },
    );
  }
}

