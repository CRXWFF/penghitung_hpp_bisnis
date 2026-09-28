import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_palette.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_theme.dart';
import 'package:penghitung_hpp_bisnis/features/history/presentation/history_screen.dart';
import 'package:penghitung_hpp_bisnis/features/home/presentation/home_screen.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/presentation/ingredients_screen.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/presentation/recipes_screen.dart';
import 'package:penghitung_hpp_bisnis/features/settings/presentation/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    // ponytail: `system` maps to ThemeMode.system. DESIGN.md and the mocks only
    // specify light; dark is derived from the same tokens in app_theme.dart.
    final mode = switch (settings.themeMode) {
      ThemeOption.system => ThemeMode.system,
      ThemeOption.light => ThemeMode.light,
      ThemeOption.dark => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'Recipe & HPP Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const Root(),
    );
  }
}

class Root extends ConsumerStatefulWidget {
  const Root({super.key});

  @override
  ConsumerState<Root> createState() => _RootState();
}

class _RootState extends ConsumerState<Root> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    IngredientsScreen(),
    RecipesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  // Icons + labels lifted from the mock <nav> in every screen_mock file.
  static const _icons = <IconData>[
    Icons.dashboard_outlined,
    Icons.menu_book_outlined,
    Icons.egg_alt_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];
  static const _filled = <IconData>[
    Icons.dashboard,
    Icons.menu_book,
    Icons.egg_alt,
    Icons.receipt_long,
    Icons.settings,
  ];
  static const _labels = ['Home', 'Resep', 'Bahan', 'Riwayat', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _PillBottomNav(
        index: _index,
        onSelected: (i) => setState(() => _index = i),
        icons: _icons,
        filledIcons: _filled,
        labels: _labels,
      ),
    );
  }
}

/// Mock nav: 64px dock, safe-area padded, 48x28 pill indicator on the active
/// item, Inter label-sm beneath.
class _PillBottomNav extends StatelessWidget {
  const _PillBottomNav({
    required this.index,
    required this.onSelected,
    required this.icons,
    required this.filledIcons,
    required this.labels,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final List<IconData> icons;
  final List<IconData> filledIcons;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: index == i ? filledIcons[i] : icons[i],
                    label: labels[i],
                    selected: index == i,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? palette.pillPrimaryBg : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? palette.pillPrimaryOn : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                height: 1.4,
                letterSpacing: 0.4,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
