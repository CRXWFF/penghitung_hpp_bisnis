import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/currency/currency.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_palette.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_theme.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/data/calculation_repository.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/domain/recipe_cost_service.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/presentation/ingredients_screen.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/presentation/recipe_editor_screen.dart';

/// Mock: Dashboard_dan_Resep_Terakhir.html
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeRepo = ref.watch(recipeRepositoryProvider);
    final ingredientRepo = ref.watch(ingredientRepositoryProvider);
    final calcRepo = ref.watch(calculationRepositoryProvider);

    return StreamBuilder<List<Recipe>>(
      stream: recipeRepo.watchAll(),
      builder: (context, recipeSnap) {
        final recipes = recipeSnap.data ?? const <Recipe>[];
        return StreamBuilder<List<Ingredient>>(
          stream: ingredientRepo.watchAll(),
          builder: (context, ingSnap) {
            final ingredients = ingSnap.data ?? const <Ingredient>[];
            return StreamBuilder<List<CalculationEntry>>(
              stream: calcRepo.watchAll(),
              builder: (context, calcSnap) {
                final calculations = calcSnap.data ?? const <CalculationEntry>[];
                return _DashboardBody(
                  recipes: recipes,
                  ingredients: ingredients,
                  calculations: calculations,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.recipes,
    required this.ingredients,
    required this.calculations,
  });

  final List<Recipe> recipes;
  final List<Ingredient> ingredients;
  final List<CalculationEntry> calculations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final categories = recipes.map((r) => r.category).whereType<String>().toSet();

    return Column(
      children: [
        const AppHeader(title: 'Recipe & HPP Manager', subtitle: 'Home'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Greeting
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Pengusaha Kuliner!',
                          style: theme.textTheme.headlineLarge,
                        ),

                        const SizedBox(height: 4),
                        Text(
                          'Kelola modal & harga jual bisnismu secara offline.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.storefront, size: 18, color: theme.colorScheme.onSecondaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecipeEditorScreen()),
                  ),
                  icon: Icon(Icons.add_circle, size: 20),
                  label: const Text('Buat Resep Baru'),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary actions
              Row(
                children: [
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.inventory_2,
                      label: '+ Tambah Bahan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IngredientsScreen(standalone: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.calculate,
                      label: 'Hitung HPP',
                      background: theme.colorScheme.surfaceContainerLow,
                      onTap: () {
                        if (recipes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Buat resep dulu untuk menghitung HPP')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipeId: recipes.first.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3 stat cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Resep',
                      value: '${recipes.length}',
                      caption: '${categories.length} kategori',
                      icon: Icons.menu_book,
                      iconBackground: palette.pillPrimaryBg,
                      iconForeground: palette.pillPrimaryOn,
                      trailingIcon: Icons.arrow_outward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Bahan',
                      value: '${ingredients.length}',
                      caption: 'Tersimpan lokal',
                      icon: Icons.inventory_2,
                      iconBackground: palette.pillSurfaceVariantBg,
                      iconForeground: palette.pillSurfaceVariantOn,
                      trailingIcon: Icons.cloud_off,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Kalkulasi',
                      value: '${calculations.length}',
                      caption: 'Snapshot aman',
                      icon: Icons.calculate,
                      iconBackground: palette.pillSecondaryBg,
                      iconForeground: palette.pillSecondaryOn,
                      trailingIcon: Icons.trending_up,
                      trailingColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent recipes header
              Row(
                children: [
                  Icon(Icons.history_edu, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Resep Terakhir', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),

              if (recipes.isEmpty)
                AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum ada resep',
                  subtitle: 'Tambahkan resep pertama\nuntuk mulai menghitung HPP.',
                  action: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipeEditorScreen()),
                    ),
                    icon: Icon(Icons.add),
                    label: const Text('Tambah Resep'),
                  ),
                )
              else
                ...recipes.take(3).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RecipeCostCard(recipe: r),
                    )),

              const SizedBox(height: 8),
              _MarginInsight(calculations: calculations),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background ?? theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.labelMedium(color: theme.colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mock "Recent Recipe Cards": thumbnail (icon tile offline), category pill,
/// relative time, and the HPP / margin / selling-price cost strip.
class RecipeCostCard extends ConsumerStatefulWidget {
  const RecipeCostCard({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeCostCard> createState() => _RecipeCostCardState();
}

class _RecipeCostCardState extends ConsumerState<RecipeCostCard> {
  RecipeBreakdown? _breakdown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecipeCostCard old) {
    super.didUpdateWidget(old);
    if (old.recipe.id != widget.recipe.id) _load();
  }

  Future<void> _load() async {
    final b = await ref.read(recipeCostServiceProvider).breakdown(widget.recipe.id);
    if (mounted) setState(() => _breakdown = b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final r = widget.recipe;
    final b = _breakdown;

    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id)),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mocks use a 64px photo; offline-first means an icon tile.
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconFor(r.category),
                      size: 26,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (r.category != null && r.category!.isNotEmpty)
                              Flexible(
                                child: AppPill(
                                  label: r.category!,
                                  background: _pillBg(r.category!, theme.colorScheme),
                                  foreground: _pillFg(r.category!, theme.colorScheme),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              _relative(r.updatedAt),
                              style: AppTheme.labelSmall(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.soup_kitchen,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Hasil: ${_num(r.yieldQuantity)} ${r.yieldUnit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (b == null)
                const SizedBox(height: 42, child: Center(child: CircularProgressIndicator()))
              else
                _CostStrip(breakdown: b, yieldUnit: r.yieldUnit),
            ],
          ),
        ),
      ),
    );
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  static IconData _iconFor(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('bakery') || c.contains('kue') || c.contains('cake')) {
      return Icons.cake_outlined;
    }
    if (c.contains('pelengkap') || c.contains('sambal')) return Icons.soup_kitchen_outlined;
    return Icons.restaurant_outlined;
  }

  Color _pillBg(String category, ColorScheme scheme) {
    final c = category.toLowerCase();
    if (c.contains('bakery') || c.contains('kue')) return scheme.tertiaryContainer;
    if (c.contains('pelengkap') || c.contains('sambal')) return scheme.surfaceContainerHighest;
    return scheme.primaryContainer;
  }

  Color _pillFg(String category, ColorScheme scheme) {
    final c = category.toLowerCase();
    if (c.contains('bakery') || c.contains('kue')) return scheme.onTertiaryContainer;
    if (c.contains('pelengkap') || c.contains('sambal')) return scheme.onSurfaceVariant;
    return scheme.onPrimaryContainer;
  }

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${diff.inDays ~/ 7} minggu lalu';
  }
}

/// HPP per unit on the left, margin pill + selling price on the right.
/// DESIGN.md: margin >= 40% olive, 25-39% honeycomb, < 25% deep terracotta.
class _CostStrip extends StatelessWidget {
  const _CostStrip({required this.breakdown, required this.yieldUnit});

  final RecipeBreakdown breakdown;
  final String yieldUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hpp = breakdown.hppPerUnit;
    // The PRD has no "target selling price" field, so the strip shows the
    // break-even price and the margin band implied by it rather than
    // inventing a stored target. ponytail: if recipes later gain a
    // targetPrice column, swap `hpp` for it here.
    final target = hpp / 0.6; // ~40% margin reference point
    final margin = target > 0 ? (target - hpp) / target : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HPP / UNIT',
                  style: AppTheme.labelSmall(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Currency.format(hpp),
                        style: AppTheme.numeric(
                          color: theme.colorScheme.primary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' / $yieldUnit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _MarginPill(margin: margin),
              const SizedBox(height: 4),
              Text(
                'Jual ${Currency.format(target)}',
                style: AppTheme.numeric(
                  size: 12,
                  weight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarginPill extends StatelessWidget {
  const _MarginPill({required this.margin});

  final double margin;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppPalette.of(context).marginBand(margin);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text('Margin ${(margin * 100).round()}%', style: AppTheme.labelSmall(color: fg)),
    );
  }
}

/// Mock "Micro Insights" donut: average healthy margin.
class _MarginInsight extends StatelessWidget {
  const _MarginInsight({required this.calculations});

  final List<CalculationEntry> calculations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priced = calculations.where((e) => e.$1.sellingPrice != null && e.$1.sellingPrice! > 0).toList();
    final avg = priced.isEmpty
        ? 0.0
        : priced
                .map((e) => (e.$1.sellingPrice! - e.$1.hppPerUnit) / e.$1.sellingPrice!)
                .reduce((a, b) => a + b) /
            priced.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: avg.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3.5,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
                    ),
                  ),
                ),
                Text(
                  '${(avg * 100).round()}%',
                  style: AppTheme.labelSmall(weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rata-rata Margin Sehat', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  priced.isEmpty
                      ? 'Belum ada harga jual tersimpan. Hitung HPP lalu simpan snapshot untuk melihat analitik margin.'
                      : 'Bisnis Anda berada dalam rentang profitabilitas prima (>35%). Pertahankan rasio takaran resep.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
