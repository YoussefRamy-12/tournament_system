import 'package:flutter/material.dart';
import 'package:leader_app/network/settings_provider.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(loc.translate('account')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.blue),
                  title: Text(loc.translate('edit_name')),
                  subtitle: Text(settings.leaderName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditNameDialog(context, settings, loc),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                  title: Text(loc.translate('delete_account'), style: const TextStyle(color: Colors.red)),
                  onTap: () => _showDeleteConfirmation(context, settings, loc),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(loc.translate('appearance')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    settings.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.amber,
                  ),
                  title: Text(loc.translate('dark_mode')),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.green),
                  title: Text(loc.translate('language')),
                  trailing: DropdownButton<String>(
                    value: settings.locale.languageCode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(loc.translate('english'))),
                      DropdownMenuItem(value: 'ar', child: Text(loc.translate('arabic'))),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        settings.setLocale(Locale(value));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_size, color: Colors.purple),
                          const SizedBox(width: 16),
                          Text(loc.translate('font_size')),
                          const Spacer(),
                          Text("${(settings.fontSizeFactor * 100).toInt()}%"),
                        ],
                      ),
                      Slider(
                        value: settings.fontSizeFactor,
                        min: 0.8,
                        max: 1.5,
                        divisions: 7,
                        onChanged: (value) {
                          settings.setFontSizeFactor(value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, SettingsProvider settings, AppLocalizations loc) {
    final controller = TextEditingController(text: settings.leaderName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: loc.translate('edit_name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              settings.setLeaderName(controller.text);
              Navigator.pop(context);
            },
            child: Text(loc.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SettingsProvider settings, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('delete_account')),
        content: Text(loc.translate('confirm_delete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await settings.deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/scanner', (route) => false);
              }
            },
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );
  }
}
