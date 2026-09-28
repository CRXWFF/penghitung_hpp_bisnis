import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/currency/currency.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit_conversion_service.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/presentation/ingredients_screen.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/data/recipe_repository.dart';

/// Create (recipeId == null) or edit an existing recipe.
/// No dedicated mock; follows the tonal-card / pill language of the four mocks.
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, this.recipeId});

  final int? recipeId;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _yieldQtyCtrl;
  late final TextEditingController _instructionsCtrl;

  Unit _yieldUnit = Unit.parse('pcs')!;
  final List<_LineForm> _lines = [];
  final List<_CostForm> _costs = [];
  String? _error;
  // Only show the spinner when we actually have to fetch an existing recipe.
  // Leaving this true in create mode meant the form never rendered.
  late bool _loading;

  bool get _isEdit => widget.recipeId != null;

  @override
  void initState() {
    super.initState();
    _loading = _isEdit;
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _yieldQtyCtrl = TextEditingController();
    _instructionsCtrl = TextEditingController();
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(recipeRepositoryProvider);
    final r = await repo.getById(widget.recipeId!);
    if (r == null) {
      setState(() => _loading = false);
      return;
    }
    _nameCtrl.text = r.name;
    _descCtrl.text = r.description ?? '';
    _categoryCtrl.text = r.category ?? '';
    _yieldQtyCtrl.text = _num(r.yieldQuantity);
    _yieldUnit = Unit.parse(r.yieldUnit) ?? _yieldUnit;
    _instructionsCtrl.text = r.instructions ?? '';

    final lines = await repo.getLines(r.id);
    final costs = await repo.getCosts(r.id);
    if (!mounted) return;
    setState(() {
      _lines.addAll(lines.map((l) => _LineForm(
            ingredientId: l.ingredient.id,
            name: l.ingredient.name,
            qty: l.quantity,
            unit: l.unit,
          )));
      _costs.addAll(costs.map((c) => _CostForm(
            name: c.name,
            amount: c.amount,
            type: CostTypeLabel.parse(c.type),
          )));
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _yieldQtyCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Memuat...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlassAppBar(title: _isEdit ? 'Edit Resep' : 'Tambah Resep'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Group(
              title: 'Info Resep',
              dotColor: theme.colorScheme.primary,
              children: [
                _Field(
                  label: 'Nama resep *',
                  hint: 'Contoh: Ayam Geprek',
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama resep wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _Field(label: 'Deskripsi', controller: _descCtrl, maxLines: 2),
                const SizedBox(height: 12),
                _Field(label: 'Kategori', hint: 'Contoh: Makanan Berat', controller: _categoryCtrl),
              ],
            ),
            const SizedBox(height: 20),

            _Group(
              title: 'Hasil Produksi',
              dotColor: theme.colorScheme.secondary,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _Field(
                        label: 'Jumlah *',
                        controller: _yieldQtyCtrl,
                        numeric: true,
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
                      child: DropdownButtonFormField<Unit>(
                        initialValue: _yieldUnit,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        items: [
                          for (final u in Unit.forSystem(UnitKind.count, imperial: false))
                            DropdownMenuItem(value: u, child: Text(u.symbol)),
                        ],
                        onChanged: (u) => setState(() => _yieldUnit = u!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            DotSectionHeader(
              title: 'Bahan (${_lines.length})',
              dotColor: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 8),
            if (_lines.isEmpty)
              TonalCard(
                child: Text(
                  'Belum ada bahan. Harga otomatis diambil dari database bahan.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._lines.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _IngredientLineCard(
                        form: e.value,
                        onRemove: () => setState(() => _lines.removeAt(e.key)),
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addIngredient,
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                side: BorderSide.none,
                foregroundColor: theme.colorScheme.primary,
              ),
              icon: Icon(Icons.add, size: 18),
              label: const Text('Tambah bahan'),
            ),
            const SizedBox(height: 20),

            DotSectionHeader(
              title: 'Biaya Tambahan (${_costs.length})',
              dotColor: theme.colorScheme.primaryContainer,
            ),
            const SizedBox(height: 8),
            if (_costs.isEmpty)
              TonalCard(
                child: Text(
                  'Gas, listrik, kemasan, tenaga kerja, dan lainnya.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._costs.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CostCard(
                        form: e.value,
                        onRemove: () => setState(() => _costs.removeAt(e.key)),
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _costs.add(_CostForm())),
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                side: BorderSide.none,
                foregroundColor: theme.colorScheme.primary,
              ),
              icon: Icon(Icons.add, size: 18),
              label: const Text('Tambah biaya'),
            ),
            const SizedBox(height: 20),

            _Group(
              title: 'Instruksi',
              dotColor: theme.colorScheme.outlineVariant,
              children: [
                _Field(
                  label: 'Langkah-langkah',
                  hint: '1. Marinasi ayam\n2. Balur dengan tepung\n3. Goreng',
                  controller: _instructionsCtrl,
                  maxLines: 6,
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Resep'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addIngredient() async {
    final selected = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
    if (selected == null || !mounted) return;
    if (_lines.any((l) => l.ingredientId == selected.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.name} sudah ada di daftar')),
      );
      return;
    }
    setState(() => _lines.add(_LineForm(
          ingredientId: selected.id,
          name: selected.name,
          unit: Unit.parse(selected.baseUnit)!,
        )));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _error = null);

    for (final l in _lines) {
      if (l.qty <= 0) {
        setState(() => _error = 'Jumlah bahan "${l.name}" harus lebih dari 0');
        return;
      }
    }

    final draft = RecipeDraft(
      name: _nameCtrl.text,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      yieldQuantity: double.parse(_yieldQtyCtrl.text.replaceAll(',', '.')),
      yieldUnitSymbol: _yieldUnit.symbol,
      instructions: _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim(),
      lines: _lines
          .map((l) => RecipeLineDraft(
                ingredientId: l.ingredientId,
                quantity: l.qty,
                unitSymbol: l.unit.symbol,
              ))
          .toList(),
      costs: _costs
          .where((c) => c.name.trim().isNotEmpty && c.amount > 0)
          .map((c) => RecipeCostDraft(
                name: c.name.trim(),
                amount: c.amount,
                type: c.type,
              ))
          .toList(),
    );

    try {
      draft.validate();
      final repo = ref.read(recipeRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.recipeId!, draft);
      } else {
        await repo.insert(draft);
      }
      if (mounted) Navigator.pop(context);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message?.toString() ?? 'Data tidak valid');
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan. Coba lagi.');
    }
  }

  static String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.dotColor, required this.children});

  final String title;
  final Color dotColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DotSectionHeader(title: title, dotColor: dotColor),
        const SizedBox(height: 8),
        TonalCard(child: Column(children: children)),
      ],
    );
  }
}

class _LineForm {
  _LineForm({required this.ingredientId, required this.name, required this.unit, this.qty = 0});

  final int ingredientId;
  final String name;
  Unit unit;
  double qty;
}

class _CostForm {
  _CostForm({this.name = '', this.amount = 0, this.type = CostType.other});

  String name;
  double amount;
  CostType type;
}

class _IngredientLineCard extends StatefulWidget {
  const _IngredientLineCard({
    required this.form,
    required this.onRemove,
    required this.onChanged,
  });

  final _LineForm form;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_IngredientLineCard> createState() => _IngredientLineCardState();
}

class _IngredientLineCardState extends State<_IngredientLineCard> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.form.qty == 0
          ? ''
          : (widget.form.qty % 1 == 0 ? widget.form.qty.toInt().toString() : widget.form.qty.toString()),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final units = Unit.forSystem(widget.form.unit.kind, imperial: false);

    return TonalCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.form.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                        ],
                        onChanged: (v) {
                          widget.form.qty = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: DropdownButtonFormField<Unit>(
                        initialValue: units.contains(widget.form.unit) ? widget.form.unit : units.first,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          for (final u in units)
                            DropdownMenuItem(value: u, child: Text(u.symbol)),
                        ],
                        onChanged: (u) {
                          if (u == null) return;
                          final converted = const UnitConversionService()
                              .convert(widget.form.qty, widget.form.unit, u);
                          widget.form.qty = converted ?? widget.form.qty;
                          _qtyCtrl.text = widget.form.qty == widget.form.qty.roundToDouble()
                              ? widget.form.qty.toInt().toString()
                              : widget.form.qty.toString();
                          setState(() => widget.form.unit = u);
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: widget.onRemove,
            tooltip: 'Hapus bahan',
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatefulWidget {
  const _CostCard({required this.form, required this.onRemove, required this.onChanged});

  final _CostForm form;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_CostCard> createState() => _CostCardState();
}

class _CostCardState extends State<_CostCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.form.name);
    _amountCtrl = TextEditingController(
      text: widget.form.amount == 0
          ? ''
          : (widget.form.amount % 1 == 0
              ? widget.form.amount.toInt().toString()
              : widget.form.amount.toString()),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TonalCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama biaya',
                    hintText: 'Kemasan',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) {
                    widget.form.name = v;
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          prefixText: 'Rp ',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) {
                          widget.form.amount = double.tryParse(v) ?? 0;
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<CostType>(
                        initialValue: widget.form.type,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          for (final t in CostType.values)
                            DropdownMenuItem(
                              value: t,
                              child: Text(t.label, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (t) {
                          if (t == null) return;
                          setState(() => widget.form.type = t);
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: widget.onRemove,
            tooltip: 'Hapus biaya',
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.numeric = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool numeric;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _IngredientPickerSheet extends ConsumerStatefulWidget {
  const _IngredientPickerSheet();

  @override
  ConsumerState<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends ConsumerState<_IngredientPickerSheet> {
  String _query = '';

  /// Opens the add-ingredient sheet on top of this picker. The list behind is
  /// a live stream, so a newly saved ingredient shows up here immediately.
  Future<void> _openAddIngredient() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const IngredientEditorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(ingredientRepositoryProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Pilih Bahan',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari bahan...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Ingredient>>(
                stream: repo.watchAll(query: _query),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data!;
                  if (items.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: _query.isNotEmpty ? 'Bahan tidak ditemukan' : 'Belum ada bahan',
                      subtitle: _query.isEmpty
                          ? 'Tambahkan bahan dulu sebelum bisa memilih\nbahan untuk resep ini.'
                          : 'Coba kata kunci lain.',
                      // Give the user a way out of the dead end without going back.
                      action: _query.isEmpty
                          ? FilledButton.icon(
                              onPressed: _openAddIngredient,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Bahan'),
                            )
                          : null,
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final ing = items[i];
                      return ListTile(
                        title: Text(ing.name),
                        subtitle: Text(
                          '${Currency.format(ing.purchasePrice)} / '
                          '${ing.purchaseQuantity % 1 == 0 ? ing.purchaseQuantity.toInt() : ing.purchaseQuantity} ${ing.purchaseUnit}',
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, ing),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
