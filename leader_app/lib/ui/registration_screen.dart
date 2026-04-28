import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/feedback_screen.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/connectivity_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure we are connected to WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectivityProvider>().connect();
    });
  }

  void _register() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('please_enter_name'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await auth.register(_nameController.text.trim());

      if (success) {
        // Sync name with settings provider for immediate UI update in home
        if (mounted) {
          context.read<SettingsProvider>().setLeaderName(
            _nameController.text.trim(),
          );
        }
        // Navigation is handled by main.dart listener
      } else {
        throw Exception(auth.errorMessage ?? "Registration failed");
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(
              success: false,
              title: loc.translate('error'),
              message: e.toString(),
              primaryButtonLabel: loc.translate('try_again'),
              primaryButtonIcon: Icons.refresh_rounded,
              onPrimaryAction: () => Navigator.pop(context),
              secondaryButtonLabel: loc.translate('cancel'),
              onSecondaryAction: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivity = context.watch<ConnectivityProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('leader_registration')),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Hero Icon/Illustration
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Connection Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: connectivity.isOnline
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: connectivity.isOnline
                          ? Colors.green.withOpacity(0.5)
                          : Colors.orange.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: connectivity.isOnline
                              ? Colors.green
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        connectivity.isOnline
                            ? loc.translate('connected_to_server')
                            : loc.translate('searching_for_server'),
                        style: TextStyle(
                          color: connectivity.isOnline
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('registration_instruction'),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      PremiumTextField(
                        controller: _nameController,
                        label: loc.translate('full_name'),
                        prefixIcon: Icons.person_outline,
                        hintText: "e.g. John Doe",
                      ),
                      const SizedBox(height: 32),
                      PremiumButton(
                        label: loc.translate('register_and_continue'),
                        onPressed: _isSubmitting ? null : _register,
                        isLoading: _isSubmitting,
                        icon: Icons.arrow_forward,
                      ),
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
