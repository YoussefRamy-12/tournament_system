import 'package:flutter/material.dart';
import 'package:leader_app/providers/auth_provider.dart';
import 'package:leader_app/providers/settings_provider.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('settings')),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.darkSurface]
                : [AppTheme.lightBg, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(context, loc.translate('account')),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.blue,
                      title: loc.translate('edit_name'),
                      subtitle: settings.leaderName,
                      onTap: () => _showEditNameDialog(context, settings, loc),
                    ),
                    _buildDivider(isDark),
                    _buildSettingTile(
                      context,
                      icon: Icons.delete_forever_outlined,
                      iconColor: Colors.red,
                      title: loc.translate('delete_account'),
                      titleColor: Colors.red,
                      onTap: () =>
                          _showDeleteConfirmation(context, settings, loc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, loc.translate('appearance')),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        settings.themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.amber,
                      ),
                      title: Text(loc.translate('dark_mode')),
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        settings.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    ListTile(
                      leading: const Icon(
                        Icons.translate_rounded,
                        color: Colors.green,
                      ),
                      title: Text(loc.translate('language')),
                      trailing: DropdownButton<String>(
                        value: settings.locale.languageCode,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(loc.translate('english')),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text(loc.translate('arabic')),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value != null) settings.setLocale(Locale(value));
                        },
                      ),
                    ),
                    _buildDivider(isDark),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.format_size_rounded,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 16),
                              Text(loc.translate('font_size')),
                              const Spacer(),
                              Text(
                                "${(settings.fontSizeFactor * 100).toInt()}%",
                              ),
                            ],
                          ),
                          Slider(
                            value: settings.fontSizeFactor,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            activeColor: AppTheme.primary,
                            onChanged: (value) =>
                                settings.setFontSizeFactor(value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  "Version 1.0.0 Premium",
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white38
              : Colors.black38,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white10 : Colors.black12,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations loc,
  ) {
    final controller = TextEditingController(text: settings.leaderName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.translate('edit_name')),
        content: PremiumTextField(
          controller: controller,
          label: loc.translate('full_name'),
          prefixIcon: Icons.person_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          PremiumButton(
            label: loc.translate('save'),
            onPressed: () {
              settings.setLeaderName(controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.translate('delete_account')),
        content: Text(loc.translate('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          PremiumButton(
            label: loc.translate('delete'),
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
            ),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await settings.deleteAccount();
              auth.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/scanner', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
