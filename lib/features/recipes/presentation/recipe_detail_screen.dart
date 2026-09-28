import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/currency/currency.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_palette.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_theme.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/domain/recipe_cost_service.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/presentation/recipe_editor_screen.dart';

/// Mock: Detail_Resep_dan_Kalkulator_HPP.html
/// Hero banner, costed ingredient lines with % contribution, HPP highlight,
/// and the interactive margin/markup selling-price simulator.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final int recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  RecipeBreakdown? _breakdown;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await ref.read(recipeCostServiceProvider).breakdown(widget.recipeId);
      if (mounted) {
        setState(() {
          _breakdown = b;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = _breakdown;

    if (_loading) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Memuat...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (b == null) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Resep'),
        body: const AppEmptyState(
          icon: Icons.error_outline,
          title: 'Resep tidak ditemukan',
          subtitle: 'Resep ini mungkin sudah dihapus.',
        ),
      );
    }

    final r = b.recipe;

    return Scaffold(
      appBar: GlassAppBar(
        title: r.name,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Resep',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditorScreen(recipeId: r.id),
                ),
              );
              _load();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HeroBanner(recipe: r),
          const SizedBox(height: 20),

          // Section 1: costed ingredients with % contribution
          DotSectionHeader(
            title: 'Daftar Bahan Baku (${b.lines.length} item)',
            dotColor: theme.colorScheme.primary,
            trailing: _TagChip(label: 'Komponen Utama'),
          ),
          const SizedBox(height: 8),
          TonalCard(
            child: Column(
              children: [
                for (var i = 0; i < b.lines.length; i++) ...[
                  _CostedLineRow(
                    line: b.lines[i],
                    share: b.totalCost > 0 ? b.lines[i].totalCost / b.totalCost : 0,
                    isLast: i == b.lines.length - 1,
                  ),
                ],
                if (b.lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Belum ada bahan di resep ini.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  _SubtotalStrip(label: 'Subtotal Bahan Baku', value: b.materialCost, color: theme.colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: additional costs
          if (b.costs.isNotEmpty) ...[
            DotSectionHeader(
              title: 'Biaya Tambahan (Overhead & Kemasan)',
              dotColor: theme.colorScheme.tertiary,
              trailing: _TagChip(label: 'Operasional'),
            ),
            const SizedBox(height: 8),
            TonalCard(
              child: Column(
                children: [
                  for (final c in b.costs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconForCost(c.name),
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Biaya tambahan produksi',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Currency.format(c.amount),
                            style: AppTheme.numeric(weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  _SubtotalStrip(
                    label: 'Subtotal Biaya Tambahan',
                    value: b.additionalCost,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 3: HPP calculation
          DotSectionHeader(
            title: 'Kalkulasi HPP (Harga Pokok Produksi)',
            dotColor: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          TonalCard(
            child: Column(
              children: [
                _CalcRow(label: 'Bahan Baku Pokok', value: b.materialCost),
                if (b.additionalCost > 0)
                  _CalcRow(label: 'Biaya Operasional Tambahan', value: b.additionalCost),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _CalcRow(label: 'Total Biaya Resep Batch', value: b.totalCost, emphasis: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Hasil Produksi Jadi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_num(r.yieldQuantity)} ${r.yieldUnit}',
                            style: AppTheme.labelMedium(weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HppHighlight(
                  hpp: b.hppPerUnit,
                  total: b.totalCost,
                  yieldQuantity: r.yieldQuantity,
                  yieldUnit: r.yieldUnit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 4: selling price simulator
          _SellingPriceSimulator(recipeId: r.id, hpp: b.hppPerUnit, yieldUnit: r.yieldUnit),
          const SizedBox(height: 20),

          if (r.description != null && r.description!.isNotEmpty) ...[
            DotSectionHeader(title: 'Deskripsi', dotColor: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            TonalCard(
              child: Text(r.description!, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 20),
          ],

          if ((r.instructions ?? '').trim().isNotEmpty) ...[
            DotSectionHeader(title: 'Instruksi', dotColor: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            TonalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _steps(r.instructions).length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${i + 1}. ${_steps(r.instructions)[i]}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<String> _steps(String? raw) =>
      (raw ?? '').split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  static IconData _iconForCost(String name) {
    final n = name.toLowerCase();
    if (n.contains('gas') || n.contains('bahan bakar')) return Icons.local_fire_department_outlined;
    if (n.contains('listrik') || n.contains('electric')) return Icons.bolt_outlined;
    if (n.contains('air') || n.contains('water')) return Icons.water_drop_outlined;
    if (n.contains('tenaga') || n.contains('labor') || n.contains('kerja')) return Icons.engineering_outlined;
    if (n.contains('kemasan') || n.contains('pack')) return Icons.inventory_2_outlined;
    return Icons.receipt_long_outlined;
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // The mock uses a 176px photo with a gradient overlay. Offline-first
          // (PRD 36) means no remote image, so this is a tonal block with the
          // dish icon, keeping the same layout proportions.
          Container(
            height: 176,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surfaceContainerHigh,
                  theme.colorScheme.surfaceContainerLow,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 56,
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      if (recipe.category != null && recipe.category!.isNotEmpty)
                        AppPill(
                          label: recipe.category!,
                          icon: Icons.lunch_dining,
                          background: theme.colorScheme.surfaceContainerLowest,
                          foreground: theme.colorScheme.primary,
                        ),
                      AppPill(
                        label: '${_num(recipe.yieldQuantity)} ${recipe.yieldUnit} batch',
                        icon: Icons.group_work,
                        background: theme.colorScheme.secondaryContainer,
                        foreground: theme.colorScheme.onSecondaryContainer,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        recipe.name,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((recipe.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          recipe.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.scale_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Metode: Resep Standar',
                  style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                Icon(Icons.verified_outlined, size: 15, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  'Terverifikasi Akurat',
                  style: AppTheme.labelSmall(
                    color: theme.colorScheme.secondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _CostedLineRow extends StatelessWidget {
  const _CostedLineRow({
    required this.line,
    required this.share,
    required this.isLast,
  });

  final CostedLine line;
  final double share;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.surfaceContainer),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${_num(line.quantity)} ${line.unitSymbol} @ ${Currency.format(line.unitCost)}/${line.unitSymbol}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Ref: Beli ${Currency.format(line.unitCost * 1000)}/kg',
                  style: AppTheme.labelSmall(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
            children: [
              Text(
                Currency.format(line.totalCost),
                style: AppTheme.numeric(weight: FontWeight.w700),
              ),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: AppTheme.labelSmall(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _SubtotalStrip extends StatelessWidget {
  const _SubtotalStrip({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.labelMedium(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            Currency.format(value),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({required this.label, required this.value, this.emphasis = false});

  final String label;
  final double value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasis
                  ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          Text(
            Currency.format(value),
            style: emphasis
                ? AppTheme.numeric(
                    color: theme.colorScheme.primary,
                    weight: FontWeight.w700,
                  )
                : AppTheme.numeric(),
          ),
        ],
      ),
    );
  }
}

class _HppHighlight extends StatelessWidget {
  const _HppHighlight({
    required this.hpp,
    required this.total,
    required this.yieldQuantity,
    required this.yieldUnit,
  });

  final double hpp;
  final double total;
  final double yieldQuantity;
  final String yieldUnit;

  @override
  Widget build(BuildContext context) {
    final q = yieldQuantity % 1 == 0 ? yieldQuantity.toInt().toString() : yieldQuantity.toString();
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.highlightBgStart, palette.highlightBgEnd],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HPP PER ${yieldUnit.toUpperCase()}',
                  style: AppTheme.labelSmall(
                    color: palette.highlightOnVariant,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Currency.format(hpp),
                    style: AppTheme.numeric(
                      size: 32,
                      color: palette.highlightOn,
                      weight: FontWeight.w700,
                    ).copyWith(height: 1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${Currency.format(total)} ÷ $q $yieldUnit',
                  style: AppTheme.labelSmall(color: palette.highlightOnVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.highlightOn.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calculate, size: 28, color: palette.highlightOn),
          ),
        ],
      ),
    );
  }
}

/// Mock "Simulasi Harga Jual": margin/markup tabs, stepper + presets,
/// live formula readout, exact vs rounded price, and estimated profit.
class _SellingPriceSimulator extends ConsumerStatefulWidget {
  const _SellingPriceSimulator({
    required this.recipeId,
    required this.hpp,
    required this.yieldUnit,
  });

  final int recipeId;
  final double hpp;
  final String yieldUnit;

  @override
  ConsumerState<_SellingPriceSimulator> createState() => _SellingPriceSimulatorState();
}

class _SellingPriceSimulatorState extends ConsumerState<_SellingPriceSimulator> {
  PricingMethod _method = PricingMethod.margin;
  int _percent = 40;
  bool _saving = false;

  static const _presets = [30, 40, 50, 60];

  double get _exact {
    final rate = _percent / 100;
    return switch (_method) {
      PricingMethod.margin => rate >= 1 ? 0 : widget.hpp / (1 - rate),
      PricingMethod.markup => widget.hpp * (1 + rate),
    };
  }

  /// UMKM pricing convention from the mock: round up to the nearest 500.
  double get _rounded {
    if (_exact <= 0) return 0;
    return (_exact / 500).ceil() * 500;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = _percent / 100;
    final profit = _rounded - widget.hpp;
    final actualMargin = _rounded > 0 ? profit / _rounded : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DotSectionHeader(
          title: 'Simulasi Harga Jual',
          dotColor: theme.colorScheme.primaryContainer,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 14, color: theme.colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                'Interactive',
                style: AppTheme.labelSmall(color: theme.colorScheme.secondary, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TonalCard(
          child: Column(
            children: [
              // Segmented tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _MethodTab(
                      label: 'Margin',
                      selected: _method == PricingMethod.margin,
                      badge: 'Rekomendasi',
                      onTap: () => setState(() {
                        _method = PricingMethod.margin;
                        _percent = 40;
                      }),
                    ),
                    _MethodTab(
                      label: 'Markup',
                      selected: _method == PricingMethod.markup,
                      onTap: () => setState(() {
                        _method = PricingMethod.markup;
                        _percent = 68;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Explainer
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _method == PricingMethod.margin
                                  ? 'Konsep Margin: '
                                  : 'Konsep Markup: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: _method == PricingMethod.margin
                                  ? 'Dihitung dari harga jual final, sedangkan Markup dihitung langsung dari modal HPP dasar.'
                                  : 'Keuntungan ditambahkan langsung ke atas HPP dasar. Margin final akan selalu lebih kecil dari persentase markup.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stepper
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _method == PricingMethod.margin ? 'Target Margin (%)' : 'Target Markup (%)',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _StepButton(
                    icon: Icons.remove,
                    onTap: _percent > 5 ? () => setState(() => _percent -= 5) : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_percent%',
                      textAlign: TextAlign.center,
                      style: AppTheme.numeric(
                        color: theme.colorScheme.primary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    onTap: _percent < 90 ? () => setState(() => _percent += 5) : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Preset:',
                    style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  ..._presets.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppPill(
                          label: '$p%',
                          selected: _percent == p,
                          onTap: () => setState(() => _percent = p),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 12),

              // Formula callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FORMULA AKTIF',
                      style: AppTheme.labelSmall(
                        color: theme.colorScheme.onSurfaceVariant,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _method == PricingMethod.margin
                          ? 'HPP / (1 - Margin) = ${Currency.format(widget.hpp)} / (1 - ${rate.toStringAsFixed(2)})'
                          : 'HPP × (1 + Markup) = ${Currency.format(widget.hpp)} × (1 + ${rate.toStringAsFixed(2)})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Exact vs rounded
              Row(
                children: [
                  Expanded(
                    child: _PriceBox(
                      label: 'Harga Hitungan',
                      value: Currency.format(_exact),
                      caption: 'Nilai presisi rumus',
                      background: theme.colorScheme.surfaceContainerLow,
                      valueColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PriceBox(
                      label: 'Rekomendasi Jual',
                      value: Currency.format(_rounded),
                      caption: 'Pembulatan ratusan UMKM',
                      background: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      valueColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Profit banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, size: 22, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Estimasi Laba Bersih / ${widget.yieldUnit}',
                          style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          Currency.format(profit),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${(actualMargin * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.save, size: 20),
          label: const Text('Simpan Snapshot Kalkulasi'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipeId: widget.recipeId)),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            side: BorderSide.none,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          icon: Icon(Icons.edit_note, size: 20),
          label: const Text('Edit Resep & Bahan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final b = await ref.read(recipeCostServiceProvider).breakdown(widget.recipeId);
      await ref.read(recipeCostServiceProvider).saveSnapshot(
            b,
            method: _method,
            percentage: _percent / 100,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalkulasi disimpan ke riwayat')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kalkulasi')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MethodTab extends StatelessWidget {
  const _MethodTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Expanded(
      child: Material(
        color: selected ? palette.cardBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      badge!,
                      style: AppTheme.labelSmall(
                        color: theme.colorScheme.onSecondaryContainer,
                        size: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: onTap == null
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.label,
    required this.value,
    required this.caption,
    required this.background,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color background;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTheme.labelSmall(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
