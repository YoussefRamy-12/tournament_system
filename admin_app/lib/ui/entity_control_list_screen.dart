import 'dart:convert';
import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/online_leader_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class EntityControlList extends StatefulWidget {
  final String type; // "Teams", "Members", or "Leaders"
  const EntityControlList({super.key, required this.type});

  @override
  State<EntityControlList> createState() => _EntityControlListState();
}

class _EntityControlListState extends State<EntityControlList> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
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
      _applySearch();
    });
  }

  void _applySearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  String _getTypeKey() {
    if (widget.type == "Members") return "players";
    return widget.type.toLowerCase();
  }

  String _getItemKey() {
    if (widget.type == "Members") return "player";
    if (widget.type == "Teams") return "team";
    return "leader";
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeKey = _getTypeKey();

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate(typeKey))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () =>
                widget.type == "Members"
                    ? _showPlayerEditorDialog(null, loc)
                    : _showEditorDialog(null, loc),
        icon: const Icon(Icons.add_rounded),
        label: Text("${loc.translate('add')} ${loc.translate(_getItemKey())}"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
        ),
        child: Column(
          children: [
            // ─── Search Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceSm,
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applySearch();
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      "${loc.translate('search')} ${loc.translate(typeKey)}...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed:
                                () => setState(() {
                                  _searchQuery = "";
                                  _applySearch();
                                }),
                          )
                          : null,
                  filled: true,
                  fillColor:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ─── Count pill ─────────────────────────────────────────
            if (_filteredData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      "${_filteredData.length} ${loc.translate(typeKey)}",
                      style: AppTheme.label12.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spaceSm),

            // ─── List ────────────────────────────────────────────────
            Expanded(
              child:
                  _filteredData.isEmpty
                      ? Center(
                        child:
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color:
                                      isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                ),
                                const SizedBox(height: AppTheme.spaceMd),
                                Text(
                                  _searchQuery.isEmpty
                                      ? "${loc.translate('no_results_for')} ${loc.translate(typeKey)}"
                                      : "${loc.translate('no_results_for')} \"$_searchQuery\"",
                                  style: AppTheme.body16.copyWith(
                                    color:
                                        isDark
                                            ? AppTheme.darkMutedTextColor
                                            : AppTheme.lightMutedTextColor,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(),
                      )
                      : ListView.builder(
                        key: ValueKey(_searchQuery),
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceMd,
                          0,
                          AppTheme.spaceMd,
                          100,
                        ),
                        itemCount: _filteredData.length,
                        itemBuilder: (context, index) {
                          final item = _filteredData[index];
                          return _buildItemCard(item, isDark, index, loc);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
    bool isDark,
    int index,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        key: ValueKey(item['id']),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              (item['name']?.toString().isNotEmpty == true)
                  ? item['name'].toString()[0].toUpperCase()
                  : '?',
              style: AppTheme.title18.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ),
        title: Text(
          item['name'] ?? loc.translate('name'),
          style: AppTheme.body16.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
          ),
        ),
        subtitle:
            (widget.type == "Members")
                ? Text(
                  "ID: ${item['id']}",
                  style: AppTheme.label12.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              tooltip: loc.translate('edit'),
              onPressed:
                  () =>
                      widget.type == "Members"
                          ? _showPlayerEditorDialog(item, loc)
                          : _showEditorDialog(item, loc),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
              tooltip: loc.translate('delete'),
              onPressed: () => _confirmDelete(item['id'], loc),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.04, end: 0);
  }

  void _confirmDelete(dynamic id, AppLocalizations loc) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            title: Text(loc.translate("delete_confirm_title")),
            content: Text(
              "${loc.translate('delete_confirm_content')}\n(${loc.translate(_getTypeKey())})",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.translate("cancel")),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  minimumSize: const Size(80, 44),
                ),
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
                child: Text(loc.translate("delete")),
              ),
            ],
          ),
    );
  }

  void _showEditorDialog(Map<String, dynamic>? item, AppLocalizations loc) {
    final nameController = TextEditingController(text: item?['name']);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            title: Text(
              item == null
                  ? "${loc.translate('add')} ${loc.translate(_getItemKey())}"
                  : "${loc.translate('edit')} ${loc.translate(_getItemKey())}",
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.translate("name"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.translate("cancel")),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 44),
                ),
                onPressed: () async {
                  final db = await _db.database;
                  if (item == null) {
                    await db.insert(widget.type, {'name': nameController.text});
                  } else {
                    await db.update(
                      widget.type,
                      {'name': nameController.text},
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );

                    // If it's a leader, notify them over WebSocket
                    if (widget.type.toLowerCase() == 'leaders') {
                      try {
                        final String leaderId = item['id'].toString();
                        OnlineLeaderTracker.instance.sendToLeader(
                          leaderId,
                          jsonEncode({
                            'type': 'profile_update',
                            'name': nameController.text,
                          }),
                        );
                      } catch (e) {
                        // ignore if fail
                      }
                    }
                  }
                  _refreshData();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                child: Text(loc.translate("save")),
              ),
            ],
          ),
    );
  }

  void _showPlayerEditorDialog(
    Map<String, dynamic>? player,
    AppLocalizations loc,
  ) async {
    final nameController = TextEditingController(text: player?['name']);
    List<Map<String, dynamic>> teams = await _db.getAllTeams();
    int? selectedTeamId =
        player?['team_id'] ?? (teams.isNotEmpty ? teams[0]['id'] : null);
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  title: Text(
                    player == null
                        ? "${loc.translate('add')} ${loc.translate('player')}"
                        : "${loc.translate('edit')} ${loc.translate('player')}",
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: loc.translate("full_name"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      DropdownButtonFormField<int>(
                        initialValue: selectedTeamId,
                        decoration: InputDecoration(
                          labelText: loc.translate("assign_to_team"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        items:
                            teams.map((team) {
                              return DropdownMenuItem<int>(
                                value: team['id'],
                                child: Text(team['name']),
                              );
                            }).toList(),
                        onChanged:
                            (value) =>
                                setDialogState(() => selectedTeamId = value),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(loc.translate("cancel")),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 44),
                      ),
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
                        _refreshData();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: Text(loc.translate("save_changes")),
                    ),
                  ],
                ),
          ),
    );
  }
}
