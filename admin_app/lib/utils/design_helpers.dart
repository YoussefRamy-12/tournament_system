import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Design constants and helper functions
class DesignConstants {
  // Animation durations
  static const Duration microAnimationDuration = Duration(milliseconds: 200);
  static const Duration standardAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  static const Duration transitionDuration = Duration(milliseconds: 400);

  // Stagger delays for list items
  static Duration staggerDelay(int index) {
    return Duration(milliseconds: 50 * index);
  }

  // Curve constants
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutQuart;
  static const Curve bouncyCurve = Curves.elasticOut;
}

/// Status and semantic color helpers
class ColorHelpers {
  /// Get color based on numeric score
  static Color getScoreColor(int score) {
    if (score > 0) return AppTheme.successColor;
    if (score < 0) return AppTheme.errorColor;
    return AppTheme.warningColor;
  }

  /// Get color for online status
  static Color getOnlineStatusColor(bool isOnline) {
    return isOnline ? AppTheme.successColor : Colors.grey;
  }

  /// Get background color for status with transparency
  static Color getStatusBackgroundColor(String status) {
    return AppTheme.getStatusColor(status).withValues(alpha: 0.1);
  }

  /// Get border color for status with transparency
  static Color getStatusBorderColor(String status) {
    return AppTheme.getStatusColor(status).withValues(alpha: 0.3);
  }
}

/// Icon helpers for status-based icons
class IconHelpers {
  /// Get icon for online/offline status
  static IconData getOnlineStatusIcon(bool isOnline) {
    return isOnline ? Icons.check_circle_rounded : Icons.offline_bolt_rounded;
  }

  /// Get icon for score direction
  static IconData getScoreDirectionIcon(int score) {
    if (score > 0) return Icons.trending_up_rounded;
    if (score < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  /// Get icon for entity type
  static IconData getEntityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'members':
      case 'member':
        return Icons.person_rounded;
      case 'teams':
      case 'team':
        return Icons.groups_rounded;
      case 'leaders':
      case 'leader':
        return Icons.verified_user_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

/// Dialog helper utilities
class DialogHelpers {
  /// Show styled confirmation dialog
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color confirmColor = AppTheme.primaryColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text(
          title,
          style: AppTheme.headline24,
        ),
        content: Text(
          message,
          style: AppTheme.body16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Show styled error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Icon(Icons.error_rounded, color: AppTheme.errorColor),
            SizedBox(width: AppTheme.spaceSm),
            Text(
              title,
              style: AppTheme.headline24.copyWith(color: AppTheme.errorColor),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.body16,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show styled success dialog
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
            SizedBox(width: AppTheme.spaceSm),
            Text(
              title,
              style: AppTheme.headline24.copyWith(color: AppTheme.successColor),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.body16,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Snackbar helper utilities
class SnackBarHelpers {
  /// Show styled success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppTheme.spaceSm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: EdgeInsets.all(AppTheme.spaceMd),
      ),
    );
  }

  /// Show styled error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: AppTheme.spaceSm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: EdgeInsets.all(AppTheme.spaceMd),
      ),
    );
  }

  /// Show styled info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Colors.white),
            SizedBox(width: AppTheme.spaceSm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.infoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: EdgeInsets.all(AppTheme.spaceMd),
      ),
    );
  }
}

/// Responsive design helpers
class ResponsiveHelper {
  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is small (mobile)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is medium (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if device is large (desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Get number of columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 1200) return 2;
    return 3;
  }
}
