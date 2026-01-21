import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';

class EntityControlList extends StatefulWidget {
  final String type; // "Teams", "Members", or "Leaders"
  const EntityControlList({super.key, required this.type});

  @override
  State<EntityControlList> createState() => _EntityControlListState();
}

class _EntityControlListState extends State<EntityControlList> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _data = [];
  // List<Map<String, dynamic>> _allData = []; // Full list from DB
  List<Map<String, dynamic>> _filteredData = []; // What actually shows
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final db = await _db.database;
    final res = await db.query(widget.type, orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      _data = res;
      _applySearch(); // Update the filtered list
    });
  }

  void _applySearch() {
    // We use a post-frame callback to prevent the 'debugDuringDeviceUpdate' crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Safety check

      setState(() {
        if (_searchQuery.isEmpty) {
          _filteredData = List.from(_data);
        } else {
          _filteredData =
              _data.where((item) {
                final name = item['name']?.toString().toLowerCase() ?? "";
                return name.contains(_searchQuery.toLowerCase());
              }).toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed:
            () =>
                widget.type == "Members"
                    ? _showPlayerEditorDialog(null)
                    : _showEditorDialog(null), // Null means "Add New"
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 1. Search Bar (Fixed height)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearch();
                });
              },
              decoration: InputDecoration(
                hintText: "Search ${widget.type}...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = "";
                              _applySearch();
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),

          // 2. The List (Wrapped in Expanded to prevent the crash)
          Expanded(
            child: ListView.builder(
              key: ValueKey(
                _searchQuery,
              ), // Helps Flutter differentiate between search states
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final item = _filteredData[index];
                return ListTile(
                  key: ValueKey(item['id']), // Unique key for each row
                  title: Text(item['name'] ?? 'No Name'),
                  subtitle:
                      widget.type == "Members"
                          ? Text("ID: ${item['id']} ")
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed:
                            () =>
                                widget.type == "Members"
                                    ? _showPlayerEditorDialog(item)
                                    : _showEditorDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Logic for Deleting
  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text(
              "Are you sure you want to remove this from ${widget.type}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final db = await _db.database;
                  await db.delete(
                    widget.type,
                    where: 'id = ?',
                    whereArgs: [id],
                  );
                  _refreshData();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  // Logic for Adding/Editing
  void _showEditorDialog(Map<String, dynamic>? item) {
    final nameController = TextEditingController(text: item?['name']);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              item == null ? "Add ${widget.type}" : "Edit ${widget.type}",
            ),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final db = await _db.database;
                  if (item == null) {
                    // ADD logic
                    await db.insert(widget.type, {'name': nameController.text});
                  } else {
                    // UPDATE logic
                    await db.update(
                      widget.type,
                      {'name': nameController.text},
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );
                  }
                  _refreshData();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  void _showPlayerEditorDialog(Map<String, dynamic>? player) async {
    final nameController = TextEditingController(text: player?['name']);

    // 1. Fetch the teams list from the DB
    List<Map<String, dynamic>> teams = await _db.getAllTeams();

    // 2. Track which team is selected (default to current team or first team available)
    int? selectedTeamId =
        player?['team_id'] ?? (teams.isNotEmpty ? teams[0]['id'] : null);
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    player == null ? "Add New Player" : "Edit Player Details",
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: selectedTeamId,
                        decoration: const InputDecoration(
                          labelText: "Assign to Team",
                          border: OutlineInputBorder(),
                        ),
                        items:
                            teams.map((team) {
                              return DropdownMenuItem<int>(
                                value: team['id'],
                                child: Text(team['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          // This updates the value inside the dialog immediately
                          setDialogState(() => selectedTeamId = value);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            selectedTeamId == null) {
                          return;
                        }

                        final db = await _db.database;
                        final data = {
                          'name': nameController.text,
                          'team_id': selectedTeamId,
                        };

                        if (player == null) {
                          await db.insert('Members', data);
                        } else {
                          await db.update(
                            'Members',
                            data,
                            where: 'id = ?',
                            whereArgs: [player['id']],
                          );
                        }

                        _refreshData(); // Refresh the list on the main screen
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
          ),
    );
  }
}
