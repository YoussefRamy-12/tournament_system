import 'package:flutter/material.dart';
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/network/connection_manager.dart';
// import 'package:leader_app/ui/MyHomePage.dart';
import 'package:leader_app/ui/member_selector.dart';
import 'package:leader_app/ui/my_home_page.dart';
import 'package:leader_app/ui/registration_screen.dart';
import 'package:leader_app/ui/scanner_screen.dart';
// import 'package:leader_app/ui/scoring_form_screen.dart';
import 'package:leader_app/ui/waiting_approval_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check if we have a saved connection
  final connection = ConnectionManager();
  String? savedUrl = await connection.getUrl();
  final String? leaderName = await connection.getLeaderName();
  final bool isRegistered = await connection.isRegistered();
  final apiClient = ApiClient();
  Widget initialScreen;

  if (savedUrl != null && isRegistered) {
    // 2. Ping the saved URL to see if it's still valid
    bool available = await apiClient.isServerAvailable();
    
    if (!available) {
      print("Saved IP is dead. Searching for new server IP...");
      // 3. Search for the server ONCE during startup
      await apiClient.findNewServerIP(); 
    }
  }

  if (savedUrl == null) {
    initialScreen = const ScannerScreen();
  } else if (!isRegistered) {
    initialScreen = const RegistrationScreen();
  } else {
    initialScreen = const MyHomePage(title: "test"); // Your Home Screen
  }
  print(
    " Saved URL: $savedUrl, Leader Name: $leaderName , Registered: $isRegistered ",
  );

  // runApp(const MyApp());
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // 3. If URL exists, go to home. If not, go to scanner.
      home: initialScreen,
      // initialRoute: initialRoute,
      routes: {
        // '/': (context) => const ScannerScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/home': (context) => const MyHomePage(title: 'test'),
        '/member_selector': (context) => const MemberSelector(),
        '/registration': (context) =>
            RegistrationScreen(/*serverUrl: savedUrl!*/),
        '/waiting_approval': (context) => const WaitingApprovalScreen(),
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}


