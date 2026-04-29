import 'package:admin_app/ui/entity_control_list_screen.dart';
import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

class FullControlScreen extends StatefulWidget {
  const FullControlScreen({super.key});

  @override
  State<FullControlScreen> createState() => _FullControlScreenState();
}

class _FullControlScreenState extends State<FullControlScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate("admin_command_center")),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.group_work),
                text: loc.translate("teams"),
              ),
              Tab(
                icon: const Icon(Icons.person),
                text: loc.translate("players"),
              ),
              Tab(
                icon: const Icon(Icons.shield),
                text: loc.translate("leaders"),
              ),
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
