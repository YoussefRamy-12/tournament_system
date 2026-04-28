import 'package:admin_app/database/csv_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isLoading = false;

  Future<void> _pickAndImportCsv() async {
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
              content: const Text('Import Successful!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('System Setup')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppTheme.spaceXl),
                  glassmorphism: true,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceXl),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.upload_file_rounded,
                            size: 80, color: AppTheme.primaryColor),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: AppTheme.spaceXl),
                      Text(
                        'Import Tournament Data',
                        style: AppTheme.headline24.copyWith(
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      Text(
                        'Upload a CSV file containing your members and teams. This will replace any existing player data.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body16.copyWith(
                            color: isDark
                                ? AppTheme.darkMutedTextColor
                                : AppTheme.lightMutedTextColor),
                      ),
                      const SizedBox(height: AppTheme.spaceXxl),
                      ActionButton(
                        label: _isLoading ? 'Processing...' : 'Select CSV File',
                        onPressed: _isLoading ? () {} : _pickAndImportCsv,
                        isLoading: _isLoading,
                        icon: Icons.file_present_rounded,
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
