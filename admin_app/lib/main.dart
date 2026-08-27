import 'dart:convert';
import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/tournament_server.dart';
import 'package:admin_app/ui/my_home_page.dart';
import 'package:admin_app/ui/projector_screen.dart';
import 'package:admin_app/theme/app_theme.dart';
import 'package:admin_app/providers/settings_provider.dart';
import 'package:admin_app/providers/dashboard_provider.dart';
import 'package:admin_app/services/storage_service.dart';
import 'package:admin_app/utils/app_localizations.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Multi-window secondary instances entry point
  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = args[1];
    final argument =
        args.length > 2 && args[2].isNotEmpty
            ? jsonDecode(args[2]) as Map<String, dynamic>
            : <String, dynamic>{};

    final storageService = StorageService();

    runApp(
      MultiProvider(
        providers: [
          Provider.value(value: storageService),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: storageService),
          ),
        ],
        child: ProjectorWindowApp(
          windowController: WindowController.fromWindowId(windowId),
          args: argument,
        ),
      ),
    );
    return;
  }

  // Initialize Core Services for primary window
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  final storageService = StorageService();

  // Start the Server
  final server = TournamentServer();
  await server.start();

  runApp(
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Tournament Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settings.fontSizeFactor)),
          child: Directionality(
            textDirection:
                settings.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: const MyHomePage(),
    );
  }
}

class ProjectorWindowApp extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> args;

  const ProjectorWindowApp({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Tournament Arena - Projector View',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settings.fontSizeFactor)),
          child: Directionality(
            textDirection:
                settings.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: const ProjectorStatsScreen(isSubWindow: true),
    );
  }
}
