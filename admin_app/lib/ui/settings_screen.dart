import 'package:admin_app/database/csv_service.dart';
import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/providers/settings_provider.dart';
import 'package:admin_app/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _pickAndImportCsv() async {
    final loc = AppLocalizations.of(context);
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final csvService = CsvService();
        final hasData = await csvService.hasExistingData();

        if (hasData) {
          await csvService.clearAllMembers();
        }

        await csvService.importMembersFromCsv(result.files.single.path!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('import_success')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('import_failed')}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final loc = AppLocalizations.of(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            children: [
              _buildSectionHeader(loc.translate('appearance')),
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.amber,
                      ),
                      title: Text(loc.translate('dark_mode')),
                      value: isDark,
                      onChanged: (val) => settings.toggleTheme(),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(
                        Icons.translate_rounded,
                        color: Colors.blue,
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
                          if (value != null) {
                            settings.setLocale(Locale(value));
                          }
                        },
                      ),
                    ),
                    const Divider(indent: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
              const SizedBox(height: AppTheme.spaceXxl),
              _buildSectionHeader(loc.translate('system_setup')),
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXl),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                    Text(
                      loc.translate('import_data'),
                      style: AppTheme.headline20.copyWith(
                        color:
                            isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text(
                      loc.translate('upload_csv'),
                      textAlign: TextAlign.center,
                      style: AppTheme.body16.copyWith(
                        color:
                            isDark
                                ? AppTheme.darkMutedTextColor
                                : AppTheme.lightMutedTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXxl),
                    ActionButton(
                      label:
                          _isLoading
                              ? loc.translate('processing')
                              : loc.translate('select_csv'),
                      onPressed: _isLoading ? () {} : _pickAndImportCsv,
                      isLoading: _isLoading,
                      icon: Icons.file_present_rounded,
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceXxl),
              _buildSectionHeader(loc.translate('danger_zone')),
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: Text(
                    loc.translate('clear_database'),
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(loc.translate('clear_database_subtitle')),
                  onTap: () => _confirmClearDatabase(loc),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXxl),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearDatabase(AppLocalizations loc) {
    Map<String, bool> selection = {
      'Transactions': false,
      'Members': false,
      'Teams': false,
      'leaders': false,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool allSelected = selection.values.every((v) => v);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            title: Text(loc.translate('clear_database_confirm_title')),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.translate('clear_database_confirm_content')),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: Text(loc.translate('select_all')),
                    value: allSelected,
                    onChanged: (val) {
                      setDialogState(() {
                        selection.updateAll((key, value) => val ?? false);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(),
                  ...selection.keys.map((table) {
                    return CheckboxListTile(
                      title: Text(loc.translate(table.toLowerCase())),
                      value: selection[table],
                      onChanged: (val) {
                        setDialogState(() {
                          selection[table] = val ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.translate('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onPressed: selection.values.any((v) => v)
                    ? () async {
                        List<String> selected = selection.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        
                        Navigator.pop(ctx);
                        await DatabaseHelper().clearSelectedData(selected);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate('clear_success')),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: Text(loc.translate('clear_database')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spaceMd,
        bottom: AppTheme.spaceSm,
      ),
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
}
