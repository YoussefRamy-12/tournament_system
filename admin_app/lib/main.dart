import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/tournament_server.dart';
import 'package:admin_app/ui/my_home_page.dart';
import 'package:admin_app/theme/app_theme.dart';
import 'package:admin_app/theme/theme_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper().database; // Initialize the database
  final server = TournamentServer();
  await server.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Tournament Admin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}
