import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ==================== APP CARD ====================
/// Unified card component with optional glassmorphism effect
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? elevation;
  final EdgeInsets? padding;
  final double? borderRadius;
  final bool glassmorphism;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.glassmorphism = false,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor);
    final brColor =
        borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05));

    final effectiveRadius = borderRadius ?? AppTheme.radiusLg;
    final effectivePadding = padding ?? EdgeInsets.all(AppTheme.spaceMd);

    final decoration = BoxDecoration(
      color: glassmorphism ? bgColor.withValues(alpha: 0.7) : bgColor,
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: border ?? Border.all(color: brColor, width: 1),
      boxShadow: [
        if (elevation != null && elevation! > 0)
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: elevation! * 2,
            offset: Offset(0, elevation!),
          ),
      ],
    );

    final container = Container(
      decoration: decoration,
      padding: effectivePadding,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: container,
      );
    }

    return container;
  }
}

// ==================== STATUS BADGE ====================
/// Status indicator badge with color, icon, and label
class StatusBadge extends StatelessWidget {
  final String status;
  final bool animated;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.animated = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    final icon = AppTheme.getStatusIcon(status);
    final textStyle =
        (fontSize != null)
            ? TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            )
            : AppTheme.label12.copyWith(color: color);

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: AppTheme.spaceXs),
          Text(status, style: textStyle),
        ],
      ),
    );

    if (animated) {
      return badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2.seconds, color: color.withValues(alpha: 0.1));
    }

    return badge;
  }
}

// ==================== STYLED LIST TILE ====================
/// Consistent list tile with icon, title, subtitle, and trailing
class StyledListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const StyledListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? AppTheme.primaryColor;

    return AppCard(
      backgroundColor: backgroundColor,
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spaceSm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: AppTheme.body16.copyWith(
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle!,
                  style: AppTheme.caption14.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                )
                : null,
        trailing: trailing,
      ),
    );
  }
}

// ==================== EMPTY STATE ====================
/// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppTheme.spaceLg),
          Text(
            message,
            style: AppTheme.headline24.copyWith(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppTheme.spaceSm),
            Text(
              subtitle!,
              style: AppTheme.caption14.copyWith(
                color:
                    isDark
                        ? AppTheme.darkMutedTextColor
                        : AppTheme.lightMutedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: AppTheme.spaceLg),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ==================== ACTION BUTTON ====================
/// Styled button with semantic color options
enum ActionButtonType { primary, secondary, danger }

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ActionButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ActionButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
  });

  Color _getColor() {
    switch (type) {
      case ActionButtonType.primary:
        return AppTheme.primaryColor;
      case ActionButtonType.secondary:
        return Colors.grey;
      case ActionButtonType.danger:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
        ),
        icon:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                : Icon(icon),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
      ),
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
              : Text(label),
    );
  }
}

// ==================== SECTION HEADER ====================
/// Styled section title with optional divider
class SectionHeader extends StatelessWidget {
  final String title;
  final bool showDivider;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.showDivider = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.title18.copyWith(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showDivider) ...[
            SizedBox(height: AppTheme.spaceSm),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== LOADING OVERLAY ====================
/// Full-screen or targeted loading indicator
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingOverlay({super.key, this.message, this.fullScreen = true});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        if (message != null) ...[
          SizedBox(height: AppTheme.spaceMd),
          Text(message!, style: AppTheme.body16),
        ],
      ],
    );

    if (fullScreen) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

// ==================== RANK BADGE ====================
/// Medal-style rank badge for leaderboard positions
class RankBadge extends StatelessWidget {
  final int rank;
  final double size;

  const RankBadge({super.key, required this.rank, this.size = 48});

  Color _getMedalColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  String _getMedalEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMedalColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getMedalEmoji(), style: TextStyle(fontSize: size * 0.6)),
            // Text(
            //   '#$rank',
            //   style: TextStyle(
            //     fontSize: size * 0.2,
            //     fontWeight: FontWeight.bold,
            //     color: color,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// ==================== GRADIENT CARD ====================
/// Card with gradient background
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double? borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusLg),
        child: container,
      );
    }

    return container;
  }
}

// ==================== SCORE INDICATOR ====================
/// Visual score display with color coding
class ScoreIndicator extends StatelessWidget {
  final int score;
  final bool showSign;
  final TextStyle? textStyle;

  const ScoreIndicator({
    super.key,
    required this.score,
    this.showSign = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = score >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    final sign = showSign && isPositive ? '+' : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$sign$score',
        style:
            textStyle?.copyWith(color: color) ??
            AppTheme.body16.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
