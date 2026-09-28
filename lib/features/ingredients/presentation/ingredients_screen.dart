import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/currency/currency.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_palette.dart';
import 'package:penghitung_hpp_bisnis/core/theme/app_theme.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit_conversion_service.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/data/ingredient_repository.dart';

/// Mock: Database_Bahan_Baku.html
/// [standalone] hides the tab-level header chrome when pushed from the
/// dashboard quick action, which the mock reaches via a header-less route.
class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(ingredientRepositoryProvider);

    return StreamBuilder<List<Ingredient>>(
      stream: repo.watchAll(query: _query),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snap.data!;
        final categories = all.map((i) => i.category).whereType<String>().where((c) => c.isNotEmpty).toSet().toList()..sort();
        final visible = _category == null
            ? all
            : all.where((i) => i.category == _category).toList();

        final body = ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Search + filter
            Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _IconButtonBox(
                  icon: Icons.tune,
                  tooltip: 'Filter Bahan',
                  onTap: () => _showFilterSheet(context, categories),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  AppPill(
                    label: 'Semua (${all.length})',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  ...categories.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: AppPill(
                          label: c,
                          selected: _category == c,
                          onTap: () => setState(() => _category = _category == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Count + add
            Row(
              children: [
                Text('Daftar Bahan', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 6),
                Text(
                  '${visible.length} ditampilkan',
                  style: AppTheme.labelSmall(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: AppTheme.labelMedium(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  icon: Icon(Icons.add, size: 18),
                  label: const Text('Tambah Bahan'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (visible.isEmpty)
              AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: _query.isNotEmpty || _category != null
                    ? 'Bahan tidak ditemukan'
                    : 'Belum ada bahan',
                subtitle: _query.isNotEmpty || _category != null
                    ? 'Coba kata kunci atau kategori lain.'
                    : 'Tambahkan bahan pertama\nuntuk mulai menghitung HPP.',
                action: FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: Icon(Icons.add),
                  label: const Text('Tambah Bahan'),
                ),
              )
            else
              ...visible.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _IngredientCard(
                      ingredient: i,
                      onEdit: () => _openEditor(context, ingredient: i),
                      onDelete: () async {
                        if (await _confirmDelete(context, i)) {
                          await repo.delete(i.id);
                        }
                      },
                    ),
                  )),

            const SizedBox(height: 16),
            const InfoNote(
              icon: Icons.lightbulb,
              title: 'Tips Cerdas HPP',
              body: 'Saat harga bahan berubah di pasar, perbarui harga di sini. '
                  'Kalkulasi lama Anda di menu Riwayat tetap aman dan tidak akan terpengaruh.',
            ),
          ],
        );

        if (widget.standalone) {
          return Scaffold(
            body: Column(
              children: [
                AppHeader(
                  title: 'Recipe & HPP Manager',
                  subtitle: 'Bahan',
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Column(
          children: [
            const AppHeader(title: 'Recipe & HPP Manager', subtitle: 'Bahan'),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, {Ingredient? ingredient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => IngredientEditorSheet(ingredient: ingredient),
    );
  }

  void _showFilterSheet(BuildContext context, List<String> categories) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text('Filter Kategori', style: Theme.of(ctx).textTheme.headlineSmall),
            ),
            RadioListTile<String?>(
              value: null,
              // ignore: deprecated_member_use
              groupValue: _category,
              title: const Text('Semua kategori'),
              // ignore: deprecated_member_use
              onChanged: (v) {
                setState(() => _category = v);
                Navigator.pop(ctx);
              },
            ),
            ...categories.map((c) => RadioListTile<String?>(
                  value: c,
                  // ignore: deprecated_member_use
                  groupValue: _category,
                  title: Text(c),
                  // ignore: deprecated_member_use
                  onChanged: (v) {
                    setState(() => _category = v);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Ingredient i) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${i.name}"?'),
        content: const Text(
          'Bahan akan dihapus permanen dari semua resep yang memakainya.',
        ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Cari nama bahan baku...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.outline),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.cancel, size: 18),
                    color: theme.colorScheme.outline,
                    onPressed: onClear,
                  ),
          ),
        );
      },
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  const _IconButtonBox({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Mock ingredient card: icon tile, category pill, relative time,
/// purchase summary, and a pinned footer with unit cost + recipe linkage.
class _IngredientCard extends ConsumerStatefulWidget {
  const _IngredientCard({
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });

  final Ingredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends ConsumerState<_IngredientCard> {
  int _usageCount = 0;
  List<String> _usedIn = const [];

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final recipes = await ref.read(recipeRepositoryProvider).getAll();
    final hits = <String>[];
    for (final r in recipes) {
      final lines = await ref.read(recipeRepositoryProvider).getLines(r.id);
      if (lines.any((l) => l.ingredient.id == widget.ingredient.id)) hits.add(r.name);
    }
    if (mounted) {
      setState(() {
        _usedIn = hits;
        _usageCount = hits.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final ing = widget.ingredient;
    final units = const UnitConversionService();
    final purchase = Unit.parse(ing.purchaseUnit);
    final base = Unit.parse(ing.baseUnit);
    final perBase = (base == null || purchase == null || base.kind != purchase.kind || ing.purchaseQuantity <= 0)
        ? null
        : ing.purchasePrice /
            (units.convert(ing.purchaseQuantity, purchase, base) ?? ing.purchaseQuantity);

    return Dismissible(
      key: ValueKey('ing-${ing.id}'),
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
            title: Text('Hapus "${ing.name}"?'),
            content: const Text('Bahan akan dihapus permanen dari semua resep yang memakainya.'),
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
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_iconFor(ing), size: 24, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (ing.category != null && ing.category!.isNotEmpty) ...[
                              AppPill(
                                label: ing.category!,
                                background: theme.colorScheme.primaryContainer,
                                foreground: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                '• ${_relative(ing.updatedAt)}',
                                style: AppTheme.labelSmall(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ing.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_num(ing.purchaseQuantity)} ${ing.purchaseUnit} • Beli ${Currency.format(ing.purchasePrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _IconButtonBox(
                    icon: Icons.edit,
                    tooltip: 'Ubah Bahan',
                    onTap: widget.onEdit,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Biaya Satuan',
                        style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            perBase == null ? '—' : Currency.format(perBase),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ ${base?.symbol ?? 'unit'}',
                            style: AppTheme.labelSmall(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Tooltip(
                              message: _usedIn.isEmpty ? 'Belum dipakai resep' : _usedIn.join(', '),
                              child: Text(
                                _usageCount == 0
                                    ? 'Belum dipakai'
                                    : '$_usageCount resep',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  static IconData _iconFor(Ingredient i) {
    final n = i.name.toLowerCase();
    if (n.contains('minyak') || n.contains('oil') || n.contains('lemak')) return Icons.oil_barrel_outlined;
    if (n.contains('daging') || n.contains('ayam') || n.contains('sapi')) return Icons.set_meal_outlined;
    if (n.contains('gula') || n.contains('cookie') || n.contains('cokelat')) return Icons.cookie_outlined;
    if (n.contains('kemasan') || n.contains('box') || n.contains('plasik')) return Icons.inventory_2_outlined;
    if (n.contains('susu') || n.contains('milk')) return Icons.water_drop_outlined;
    if (n.contains('telur') || n.contains('butir')) return Icons.egg_outlined;
    if (n.contains('terigu') || n.contains('tepung') || n.contains('beras')) return Icons.grain_outlined;
    return Icons.local_dining_outlined;
  }

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${diff.inDays ~/ 7} minggu lalu';
  }
}

/// Bottom-sheet form from the mock, with the live unit-cost preview.
class IngredientEditorSheet extends ConsumerStatefulWidget {
  const IngredientEditorSheet({super.key, this.ingredient});

  final Ingredient? ingredient;

  @override
  ConsumerState<IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends ConsumerState<IngredientEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;

  late UnitKind _kind;
  late Unit _purchaseUnit;
  late Unit _baseUnit;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.ingredient != null;

  static const _suggestedCategories = [
    'Tepung & Butir',
    'Daging & Unggas',
    'Minyak & Lemak',
    'Bumbu & Rempah',
    'Kemasan',
    'Lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _nameCtrl = TextEditingController(text: ing?.name ?? '');
    _categoryCtrl = TextEditingController(text: ing?.category ?? '');
    _qtyCtrl = TextEditingController(text: ing == null ? '' : _num(ing.purchaseQuantity));
    _priceCtrl = TextEditingController(text: ing == null ? '' : _num(ing.purchasePrice));
    _notesCtrl = TextEditingController(text: ing?.notes ?? '');

    final base = ing == null ? Unit.parse('g')! : Unit.parse(ing.baseUnit);
    final purchase = ing == null ? Unit.parse('kg')! : Unit.parse(ing.purchaseUnit);
    _baseUnit = base ?? Unit.parse('g')!;
    _purchaseUnit = purchase ?? _baseUnit;
    _kind = _baseUnit.kind;
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final inBase = const UnitConversionService().convert(qty, _purchaseUnit, _baseUnit);
    final perBase = (inBase == null || inBase <= 0) ? null : price / inBase;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Ubah Bahan' : 'Tambah Bahan Baru',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      color: theme.colorScheme.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Field(
                  label: 'Nama Bahan Baku',
                  controller: _nameCtrl,
                  hint: 'Contoh: Susu UHT Full Cream',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama bahan wajib diisi' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Kategori',
                  controller: _categoryCtrl,
                  hint: 'Pilih atau tulis kategori',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedCategories
                      .map((c) => AppPill(
                            label: c,
                            selected: _categoryCtrl.text == c,
                            onTap: () => setState(() => _categoryCtrl.text = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UnitKind>(
                        initialValue: _kind,
                        isDense: true,
                        decoration: const InputDecoration(labelText: 'Satuan Standar'),
                        items: [
                          for (final k in UnitKind.values)
                            DropdownMenuItem(value: k, child: Text(Unit.kindLabel(k))),
                        ],
                        onChanged: (k) => setState(() {
                          _kind = k!;
                          _baseUnit = const UnitConversionService().canonicalFor(k);
                          _purchaseUnit = switch (k) {
                            UnitKind.weight => Unit.parse('kg')!,
                            UnitKind.volume => Unit.parse('l')!,
                            UnitKind.length => Unit.parse('cm')!,
                            UnitKind.count => Unit.parse('pcs')!,
                          };
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Unit>(
                        initialValue: _purchaseUnit,
                        isDense: true,
                        decoration: const InputDecoration(labelText: 'Satuan Beli'),
                        items: [
                          for (final u in Unit.forSystem(_kind, imperial: false))
                            DropdownMenuItem(value: u, child: Text(u.symbol)),
                        ],
                        onChanged: (u) => setState(() => _purchaseUnit = u!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Kuantitas Beli',
                        controller: _qtyCtrl,
                        hint: '1000',
                        numeric: true,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                          if (d == null) return 'Wajib diisi';
                          if (d <= 0) return 'Harus > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Harga Total (Rp)',
                        controller: _priceCtrl,
                        hint: '15000',
                        numeric: true,
                        digitsOnly: true,
                        onChanged: () => setState(() {}),
                        validator: (v) {
                          final d = double.tryParse(v ?? '');
                          if (d == null) return 'Wajib diisi';
                          if (d < 0) return 'Tidak boleh negatif';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Biaya per Satuan:', style: theme.textTheme.bodySmall),
                      const Spacer(),
                      Text(
                        '${perBase == null ? 'Rp0' : Currency.format(perBase)} / ${_baseUnit.symbol}',
                        style: AppTheme.numeric(
                          color: theme.colorScheme.primary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Catatan',
                  controller: _notesCtrl,
                  hint: 'Opsional',
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          backgroundColor: theme.colorScheme.surfaceContainer,
                          side: BorderSide.none,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.check, size: 18),
                        label: Text(_isEdit ? 'Simpan' : 'Simpan Bahan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = IngredientDraft(
      name: _nameCtrl.text,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      baseUnitSymbol: _baseUnit.symbol,
      purchaseQuantity: double.parse(_qtyCtrl.text.replaceAll(',', '.')),
      purchaseUnitSymbol: _purchaseUnit.symbol,
      purchasePrice: double.parse(_priceCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      final repo = ref.read(ingredientRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.ingredient!.id, draft);
      } else {
        await repo.insert(draft);
      }
      if (mounted) Navigator.pop(context);
    } on ArgumentError catch (e) {
      setState(() {
        _saving = false;
        _error = e.message?.toString() ?? 'Data tidak valid';
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Gagal menyimpan. Coba lagi.';
      });
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.numeric = false,
    this.digitsOnly = false,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool numeric;
  final bool digitsOnly;
  final VoidCallback? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged == null ? null : (_) => onChanged!(),
      textCapitalization: textCapitalization,
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: [
        if (digitsOnly)
          FilteringTextInputFormatter.digitsOnly
        else if (numeric)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
