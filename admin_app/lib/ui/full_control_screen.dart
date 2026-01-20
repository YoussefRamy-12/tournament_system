import 'package:admin_app/ui/entity_control_list_screen.dart';
import 'package:flutter/material.dart';

class FullControlScreen extends StatelessWidget {
  const FullControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Command Center"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group_work), text: "Teams"),
              Tab(icon: Icon(Icons.person), text: "Players"),
              Tab(icon: Icon(Icons.shield), text: "Leaders"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EntityControlList(type: "Teams"),
            EntityControlList(type: "Members"),
            EntityControlList(type: "Leaders"),
          ],
        ),
      ),
    );
  }
}