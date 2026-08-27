import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../utils/app_localizations.dart';

class PlayerDetailsDialog {
  static void show(BuildContext context, Map<String, dynamic> player) async {
    final dbHelper = DatabaseHelper();
    final all = await dbHelper.getAllTransactions();

    if (!context.mounted) return;

    final loc = AppLocalizations.of(context);

    // Assuming player map has 'id' available
    final history = all.where((t) => t['target_id'] == player['id']).toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(player['name'] ?? loc.translate('unknown')),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${loc.translate('team')}: ${player['teamName'] ?? loc.translate('no_team')}",
                      style: const TextStyle(
                        color: Colors.indigoAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      "${player['totalScore'] ?? 0} ${loc.translate('pts')}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      loc.translate("total_points"),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        loc.translate("transaction_history").toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          loc.translate("no_transactions_yet"),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...history.map((t) {
                      final points = t['points'] ?? 0;
                      final isPositive = points >= 0;
                      return InkWell(
                        onTap: () => _showTransactionDetails(context, t, loc),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isPositive
                                          ? Colors.green
                                          : Colors.red)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "${isPositive ? '+' : ''}$points",
                                    style: TextStyle(
                                      color:
                                          isPositive
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${t['tag'] ?? loc.translate('score')}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${t['leaderName'] ?? loc.translate('unknown')}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${t['timestamp']?.toString().split(' ')[0]}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.translate('close')),
              ),
            ],
          ),
    );
  }

  static void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> t,
    AppLocalizations loc,
  ) {
    final points = t['points'] ?? 0;
    final isPositive = points >= 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(loc.translate('transaction_details')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailTile(
                  Icons.person_outline,
                  loc.translate('member'),
                  t['memberName'] ?? loc.translate('unknown'),
                ),
                _buildDetailTile(
                  Icons.stars_rounded,
                  loc.translate('points'),
                  '${isPositive ? "+" : ""}$points',
                  valueColor:
                      isPositive ? Colors.greenAccent : Colors.redAccent,
                ),
                _buildDetailTile(
                  Icons.label_outline,
                  loc.translate('category'),
                  t['tag'] ?? 'N/A',
                ),
                _buildDetailTile(
                  Icons.badge_outlined,
                  loc.translate('submitted_by'),
                  t['leaderName'] ?? loc.translate('unknown_leader'),
                ),
                _buildDetailTile(
                  Icons.access_time,
                  loc.translate('timestamp'),
                  t['timestamp'].toString(),
                ),
                _buildDetailTile(
                  Icons.info_outline,
                  loc.translate('status'),
                  t['status'] ?? 'N/A',
                  valueColor:
                      t['status'] == 'APPROVED'
                          ? Colors.greenAccent
                          : t['status'] == 'REJECTED'
                          ? Colors.redAccent
                          : Colors.orange,
                ),
                if (t['description'] != null &&
                    t['description'].toString().isNotEmpty) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${loc.translate('note')}: ${t['description']}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.translate('close')),
              ),
            ],
          ),
    );
  }

  static Widget _buildDetailTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigoAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
