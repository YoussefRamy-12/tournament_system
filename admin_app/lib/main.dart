import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/tournament_server.dart';
import 'package:admin_app/ui/my_home_page.dart';
import 'package:flutter/material.dart';

void main() async {
  DatabaseHelper().database; // Initialize the database
  final server = TournamentServer();
  await server.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}
