import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/tournament_server.dart';
import 'package:admin_app/ui/admin_history_screen.dart';
import 'package:admin_app/ui/connection_screen.dart';
import 'package:admin_app/ui/full_control_screen.dart';
import 'package:admin_app/ui/leader_approval_screen.dart';
import 'package:admin_app/ui/leaderboard_screen.dart';
import 'package:admin_app/ui/projector_screen.dart';
import 'package:admin_app/ui/review_screen.dart';
import 'package:admin_app/ui/setup_screen.dart';
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("home"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Inside your Admin App's main UI or Sidebar
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Review Scores'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReviewScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('qr code'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectionScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('setup screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetupScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('leaderboard screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaderboardScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('leader screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaderApprovalScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('all transactions screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminHistoryScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('projector screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectorStatsScreen(),
                    ),
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('full control screen'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullControlScreen(),
                    ),
                  ),
            ),
          ],
        ),
      ),);
  }
}
