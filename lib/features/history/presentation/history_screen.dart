import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:penghitung_hpp_bisnis/core/currency/currency.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_palette.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_theme.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/data/calculation_repository.dart';

enum _TimeFilter { all, thisMonth, lastMonth }

/// Mock: Riwayat_Kalkulasi_Snapshot.html
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _TimeFilter _filter = _TimeFilter.all;
  final _expanded = <int>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(calculationRepositoryProvider);

    return StreamBuilder<List<CalculationEntry>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final all = snap.data!;
        final now = DateTime.now();
        final thisMonth = _countIn(all, now.month, now.year);
        final lastMonth = all
            .where((e) =>
                e.$1.createdAt.isAfter(now.subtract(const Duration(days: 30))) &&
                e.$1.createdAt.isBefore(DateTime(now.year, now.month, 1)))
            .length;

        var visible = all;
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          visible = visible.where((e) => e.$2.toLowerCase().contains(q)).toList();
        }
        switch (_filter) {
          case _TimeFilter.all:
            break;
          case _TimeFilter.thisMonth:
            visible = visible
                .where((e) => e.$1.createdAt.year == now.year && e.$1.createdAt.month == now.month)
                .toList();
          case _TimeFilter.lastMonth:
            final n = DateTime(now.year, now.month, 1);
            final from = n.subtract(const Duration(days: 1));
            visible = visible
                .where((e) => e.$1.createdAt.isAfter(from) && e.$1.createdAt.isBefore(n))
                .toList();
        }

        return Column(
          children: [
            const AppHeader(title: 'Recipe & HPP Manager', subtitle: 'Riwayat'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // Header + subtitle
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Riwayat Kalkulasi HPP', style: theme.textTheme.headlineLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catatan snapshot biaya produksi yang terkunci & tidak terpengaruh '
                    'kenaikan harga bahan saat ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (context, value, _) => TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Cari resep di riwayat...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close, size: 18),
                                color: theme.colorScheme.onSurfaceVariant,
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        AppPill(
                          label: 'Semua Waktu',
                          icon: Icons.done,
                          selected: _filter == _TimeFilter.all,
                          onTap: () => setState(() => _filter = _TimeFilter.all),
                        ),
                        const SizedBox(width: 4),
                        AppPill(
                          label: 'Bulan Ini${thisMonth > 0 ? '  $thisMonth' : ''}',
                          selected: _filter == _TimeFilter.thisMonth,
                          onTap: () => setState(() => _filter = _TimeFilter.thisMonth),
                        ),
                        const SizedBox(width: 4),
                        AppPill(
                          label: 'Bulan Lalu${lastMonth > 0 ? '  $lastMonth' : ''}',
                          selected: _filter == _TimeFilter.lastMonth,
                          onTap: () => setState(() => _filter = _TimeFilter.lastMonth),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (visible.isEmpty)
                    AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: _query.isNotEmpty || _filter != _TimeFilter.all
                          ? 'Riwayat tidak ditemukan'
                          : 'Belum ada riwayat',
                      subtitle: _query.isNotEmpty || _filter != _TimeFilter.all
                          ? 'Coba kata kunci atau rentang waktu lain.'
                          : 'Hitung HPP dari halaman Resep\nuntuk mulai membuat riwayat.',
                    )
                  else
                    ...visible.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SnapshotCard(
                            entry: e,
                            isLatest: all.isNotEmpty && e.$1.id == all.first.$1.id,
                            expanded: _expanded.contains(e.$1.id),
                            onToggle: () => setState(() {
                              if (!_expanded.remove(e.$1.id)) _expanded.add(e.$1.id);
                            }),
                            onDelete: () async {
                              if (await _confirmDelete(context, e.$2)) {
                                await repo.delete(e.$1.id);
                              }
                            },
                          ),
                        )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static int _countIn(List<CalculationEntry> all, int month, int year) =>
      all.where((e) => e.$1.createdAt.year == year && e.$1.createdAt.month == month).length;

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus riwayat "$name"?'),
        content: const Text('Snapshot kalkulasi ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

class _SnapshotCard extends ConsumerStatefulWidget {
  const _SnapshotCard({
    required this.entry,
    required this.isLatest,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
  });

  final CalculationEntry entry;
  final bool isLatest;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  ConsumerState<_SnapshotCard> createState() => _SnapshotCardState();
}

class _SnapshotCardState extends ConsumerState<_SnapshotCard> {
  List<CalculationItem> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(calculationRepositoryProvider).getWithItems(widget.entry.$1.id);
    if (mounted) {
      setState(() {
        _items = result?.$2 ?? const [];
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final (calc, recipeName, yieldUnit) = widget.entry;
    final price = calc.sellingPrice;
    final margin = price != null && price > 0 ? (price - calc.hppPerUnit) / price : null;

    return Dismissible(
      key: ValueKey('calc-${calc.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Hapus riwayat "$recipeName"?'),
            content: const Text('Snapshot kalkulasi ini akan dihapus permanen.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  minimumSize: const Size(88, 44),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return res ?? false;
      },
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: widget.isLatest
              ? Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meta row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppPill(
                            label: widget.isLatest ? 'Terbaru' : 'Versi Lama',
                            icon: widget.isLatest ? Icons.stars : Icons.history,
                            background: widget.isLatest
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHigh,
                            foreground: widget.isLatest
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(calc.createdAt),
                              style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipeName,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Snapshot Terkunci',
                        style: AppTheme.labelSmall(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dish tile + HPP
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.restaurant_menu, size: 24, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'HPP Dasar / $yieldUnit',
                                style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (margin != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  'Margin ${(margin * 100).round()}%',
                                  style: AppTheme.labelSmall(color: theme.colorScheme.onSecondaryContainer),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Currency.format(calc.hppPerUnit),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $yieldUnit',
                              style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2x2 metric grid
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Total Biaya Batch',
                    value: Currency.format(calc.totalCost),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Hasil Produksi',
                    value: '${_num(calc.yieldQuantity)} $yieldUnit',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'HPP / $yieldUnit',
                    value: Currency.format(calc.hppPerUnit),
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Target Harga Jual',
                    value: price == null ? '—' : Currency.format(price),
                    valueColor: price == null ? null : theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Snapshot protection notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Terkunci: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          TextSpan(
                            text: 'angka snapshot ini merekam harga bahan saat kalkulasi dibuat '
                                'dan tidak akan berubah meski harga bahan diperbarui.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
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
            const SizedBox(height: 8),

            // Expand toggle
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loaded ? widget.onToggle : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  side: BorderSide.none,
                  minimumSize: const Size(0, 48),
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(widget.expanded ? Icons.expand_less : Icons.arrow_forward, size: 18),
                label: Text(widget.expanded ? 'Sembunyikan Rincian' : 'Lihat Rincian Lengkap'),
              ),
            ),

            // Locked composition
            if (widget.expanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOMPOSISI BAHAN TERKUNCI',
                      style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    for (final i in _items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i.name} (${_num(i.quantity)} ${i.unit})',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(Currency.format(i.totalCost), style: AppTheme.numeric(size: 12)),
                          ],
                        ),
                      ),
                    if (calc.totalAdditionalCost > 0) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Biaya tambahan',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              Currency.format(calc.totalAdditionalCost),
                              style: AppTheme.numeric(size: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Text(
                            'Total Snapshot Cost',
                            style: AppTheme.labelMedium(color: theme.colorScheme.onSurface),
                          ),
                          const Spacer(),
                          Text(
                            Currency.format(calc.totalCost),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
