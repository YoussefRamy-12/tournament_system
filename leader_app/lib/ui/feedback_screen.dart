import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';

class FeedbackScreen extends StatelessWidget {
  final bool success;
  final bool isOffline;
  final String title;
  final String message;
  final String primaryButtonLabel;
  final IconData primaryButtonIcon;
  final VoidCallback onPrimaryAction;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryAction;

  const FeedbackScreen({
    super.key,
    required this.success,
    this.isOffline = false,
    required this.title,
    required this.message,
    required this.primaryButtonLabel,
    required this.primaryButtonIcon,
    required this.onPrimaryAction,
    this.secondaryButtonLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Status Icon
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (isOffline ? Colors.orange : (success ? Colors.green : Colors.red)).withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOffline 
                            ? Icons.cloud_upload_rounded 
                            : (success ? Icons.check_circle_rounded : Icons.error_rounded),
                        size: 100,
                        color: isOffline ? Colors.orange : (success ? Colors.green : Colors.red),
                      ),
                    )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 40),

                // Title Text
                Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    )
                    .animate()
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms)
                    .fadeIn(),

                const SizedBox(height: 16),

                // Message Text
                Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    )
                    .animate()
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms)
                    .fadeIn(),

                const SizedBox(height: 60),

                // Action Buttons
                PremiumButton(
                      label: primaryButtonLabel,
                      onPressed: onPrimaryAction,
                      icon: primaryButtonIcon,
                      gradient: isOffline || success
                          ? null
                          : const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                            ),
                    )
                    .animate()
                    .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 400.ms)
                    .fadeIn(),

                if (secondaryButtonLabel != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                        onPressed:
                            onSecondaryAction ?? () => Navigator.pop(context),
                        child: Text(
                          secondaryButtonLabel!,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                      .animate()
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        delay: 500.ms,
                      )
                      .fadeIn(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
