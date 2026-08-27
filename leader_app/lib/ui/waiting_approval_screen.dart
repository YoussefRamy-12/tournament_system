import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure we are connected to WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final connectivity = context.read<ConnectivityProvider>();

      connectivity.onStatusUpdate = (status) {
        if (mounted) {
          auth.checkApproval();
        }
      };

      connectivity.connect();
    });
  }

  void _checkStatus() {
    context.read<AuthProvider>().checkApproval();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<AuthProvider>();

    // main.dart handles general routing based on auth.status.

    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Waiting Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.1),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.5, 1.5),
                          duration: 2.seconds,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 2.seconds),

                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .rotate(duration: 3.seconds),
                  ],
                ),
                const SizedBox(height: 48),

                Text(
                  loc.translate('waiting_for_approval'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                PremiumCard(
                  child: Column(
                    children: [
                      Text(
                        loc.translate('ask_admin_approval'),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 1.5.seconds,
                            color: AppTheme.secondary.withValues(alpha: 0.5),
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                PremiumButton(
                  label: loc.translate('check_status_now'),
                  onPressed: _checkStatus,
                  gradient: AppTheme.accentGradient,
                  icon: Icons.refresh_rounded,
                ),

                const SizedBox(height: 32),

                // Connection Status Helper
                Text(
                  "Stay connected to the same Wi-Fi as the Admin.",
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
