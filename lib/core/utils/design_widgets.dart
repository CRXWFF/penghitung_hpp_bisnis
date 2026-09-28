import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/models.dart';
import '../providers.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Bundled brand mark (assets/logo.svg). Vector so it stays crisp at any size
/// and needs no network fetch.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset('assets/logo.svg', fit: BoxFit.contain),
    );
  }
}

/// Frosted-glass surface: blurred backdrop + translucent tint.
/// Used for the top bar on every screen.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.72,
    this.border,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: opacity),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Quick light/dark switch for the header's right slot. The app has no auth
/// (PRD 48), so a profile avatar there would be misleading — a theme toggle is
/// a real, always-useful control instead of dead chrome.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
      ),
      tooltip: isDark ? 'Mode terang' : 'Mode gelap',
      color: theme.colorScheme.onSurfaceVariant,
      onPressed: () => _toggle(context, ref, isDark),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool isDark) async {
    final repo = ref.read(settingsRepositoryProvider);
    final updated = ref.read(appSettingsProvider).copyWith(
      themeMode: isDark ? ThemeOption.light : ThemeOption.dark,
    );
    ref.read(appSettingsProvider.notifier).state = updated;
    try {
      await repo.save(updated);
    } catch (_) {
      // Theme still applied in-session even if persistence fails; don't block UX.
    }
  }
}

/// Mock header: 64px bar, brand mark + title/subtitle, action slot.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing = const ThemeToggleButton(),
  });

  final String title;
  final String subtitle;

  /// Shown before the logo (e.g. a back button when pushed as a route).
  final Widget? leading;

  /// Right-side action. Defaults to the theme toggle so the bar is never empty.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              const AppLogo(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass app bar for pushed screens (detail / editor), so every top bar in the
/// app shares the same frosted treatment.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, required this.title, this.actions, this.leading});

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
        leading: leading,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}

/// DESIGN.md: pill-shaped chips, 24px height, label-sm.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ??
        (selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow);
    final fg = foreground ??
        (selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppTheme.labelMedium(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// DESIGN.md: 6px radius for micro UI.
/// Dashboard stat card: 3-up grid, tonal surface, icon chip + big numeral.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    this.trailingIcon,
    this.trailingColor,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconBackground;

  /// Passed explicitly rather than derived by comparing `iconBackground`
  /// against known constants — identity comparison against a Color is fragile.
  final Color iconForeground;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconForeground),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 14, color: trailingColor ?? theme.colorScheme.outlineVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.numeric(size: 22, weight: FontWeight.w700)
                .copyWith(color: theme.colorScheme.onSurface, height: 1.1),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Section heading with a colored dot, matching the detail mock.
class DotSectionHeader extends StatelessWidget {
  const DotSectionHeader({
    super.key,
    required this.title,
    required this.dotColor,
    this.trailing,
  });

  final String title;
  final Color dotColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// DESIGN.md: tonal card, no drop shadow, 12px radius.
class TonalCard extends StatelessWidget {
  const TonalCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // cardBg, not surfaceContainerLowest: in dark that role is *darker*
        // than the canvas, which would make every card look like a hole.
        color: AppPalette.of(context).cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Small note/callout block used across the mocks.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.background,
    this.foreground,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? background;
  final Color? foreground;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ?? theme.colorScheme.surfaceContainer;
    final fg = foreground ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMedium(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall?.copyWith(color: fg, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state, design-system styled.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
